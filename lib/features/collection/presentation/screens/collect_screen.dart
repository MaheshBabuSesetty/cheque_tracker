import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/entities/collection_draft.dart';
import '../../domain/entities/collection_record.dart';
import '../providers/collect_draft_notifier.dart';
import '../providers/last_submitted_record_notifier.dart';
import '../providers/main_tab_notifier.dart';
import '../providers/vendors_provider.dart';
import '../widgets/capture_tile.dart';
import '../widgets/signature_sheet.dart';
import '../widgets/step_card.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/vendor_picker_sheet.dart';

/// The Collect tab: either the 6-step "New collection" form, or the
/// success view right after a submit — swapping which is shown (rather
/// than pushing a route) keeps the bottom tab bar's Collect tab as the
/// single re-entrant home for this flow.
class CollectScreen extends ConsumerWidget {
  const CollectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRecord = ref.watch(lastSubmittedRecordProvider);
    if (lastRecord != null) {
      return _CollectionSuccessView(record: lastRecord);
    }
    return const _CollectForm();
  }
}

class _CollectForm extends ConsumerStatefulWidget {
  const _CollectForm();

  @override
  ConsumerState<_CollectForm> createState() => _CollectFormState();
}

class _CollectFormState extends ConsumerState<_CollectForm> {
  final _repNameController = TextEditingController();
  final _repMobileController = TextEditingController();
  final _chequeNumberController = TextEditingController();
  final _chequeAmountController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(collectDraftProvider);
    _repNameController.text = draft.repName;
    _repMobileController.text = draft.repMobile;
    _chequeNumberController.text = draft.chequeNumber;
    _chequeAmountController.text = draft.chequeAmount;
  }

  @override
  void dispose() {
    _repNameController.dispose();
    _repMobileController.dispose();
    _chequeNumberController.dispose();
    _chequeAmountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _submitting = true);
    final record = await ref.read(collectDraftProvider.notifier).submit();
    if (!mounted) return;
    setState(() => _submitting = false);
    if (record != null) {
      ref.read(lastSubmittedRecordProvider.notifier).set(record);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the rep-name field in sync when the notifier auto-fills it from
    // the Emirates ID scan (the controller itself is the source of truth
    // for user typing, so only reconcile on the OCR-driven path).
    ref.listen(collectDraftProvider, (previous, next) {
      if (next.nameFromOcr && _repNameController.text != next.repName) {
        _repNameController.text = next.repName;
      }
      // Cheque OCR auto-fills (on a successful scan) or clears (on
      // rejection/recapture) the number+amount fields — reconcile the
      // controllers whenever that scan status changes.
      if (previous?.chequeOcrStatus != next.chequeOcrStatus) {
        if (_chequeNumberController.text != next.chequeNumber) {
          _chequeNumberController.text = next.chequeNumber;
        }
        if (_chequeAmountController.text != next.chequeAmount) {
          _chequeAmountController.text = next.chequeAmount;
        }
      }
    });

    final draft = ref.watch(collectDraftProvider);
    final notifier = ref.read(collectDraftProvider.notifier);
    final done = draft.stepsDone;
    final doneCount = done.where((d) => d).length;
    final ready = draft.isComplete;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
          decoration: BoxDecoration(
            color: AppColors.cream,
            border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.07))),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text('New collection', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                  ),
                  Text(
                    '$doneCount OF 6 COMPLETE',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.goldLink, letterSpacing: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              StepProgressBar(progress: doneCount / 6),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 6),
            children: [
              StepCard(
                number: 1,
                title: 'Vendor',
                done: done[0],
                child: _VendorStep(draft: draft, notifier: notifier),
              ),
              StepCard(
                number: 2,
                title: 'Representative',
                done: done[1],
                child: _RepresentativeStep(
                  draft: draft,
                  notifier: notifier,
                  repNameController: _repNameController,
                  repMobileController: _repMobileController,
                ),
              ),
              StepCard(
                number: 3,
                title: 'Emirates ID',
                done: done[2],
                child: _EmiratesIdStep(draft: draft, notifier: notifier),
              ),
              StepCard(
                number: 4,
                title: 'Cheque',
                done: done[3],
                child: _ChequeStep(
                  draft: draft,
                  notifier: notifier,
                  numberController: _chequeNumberController,
                  amountController: _chequeAmountController,
                ),
              ),
              StepCard(
                number: 5,
                title: 'Voucher & documents',
                done: false,
                optional: true,
                child: _VoucherStep(draft: draft, notifier: notifier),
              ),
              StepCard(
                number: 6,
                title: 'Consent',
                done: done[4],
                tinted: true,
                child: _ConsentStep(draft: draft, notifier: notifier),
              ),
              StepCard(
                number: 7,
                title: 'Signature',
                done: done[5],
                child: _SignatureStep(draft: draft, notifier: notifier),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 11, 15, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
          ),
          child: Column(
            children: [
              Text(
                ready
                    ? 'All details captured — signature will appear on the web record.'
                    : 'Still needed: ${draft.missingStepNames.join(', ')}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: ready ? AppColors.success : AppColors.textFaint,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 9),
              AppPrimaryButton(
                label: _submitting ? 'Submitting…' : 'Submit',
                isLoading: _submitting,
                onPressed: ready && !_submitting ? _handleSubmit : null,
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VendorStep extends ConsumerWidget {
  const _VendorStep({required this.draft, required this.notifier});

  final CollectionDraft draft;
  final CollectDraftNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendor = draft.vendor;
    if (vendor != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8F1),
          border: Border.all(color: const Color(0xFFECDFB6)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vendor.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.35)),
                  const SizedBox(height: 4),
                  Text(
                    '${vendor.code} · TRN ${vendor.trn}',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.goldLink, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: notifier.clearVendor,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              child: const Text(
                'Change',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      );
    }

    final vendorCount = ref.watch(vendorsProvider).value?.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            final picked = await VendorPickerSheet.show(context);
            if (picked != null) notifier.pickVendor(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black.withValues(alpha: 0.16)),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Search vendor master…', style: TextStyle(color: AppColors.textFaint, fontSize: 14)),
                ),
                const Icon(Icons.search, size: 18, color: AppColors.textFaint),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          vendorCount != null ? 'Synced from the web master · $vendorCount active vendors' : 'Synced from the web master',
          style: const TextStyle(fontSize: 10.5, color: AppColors.textFaint),
        ),
      ],
    );
  }
}

class _RepresentativeStep extends StatelessWidget {
  const _RepresentativeStep({
    required this.draft,
    required this.notifier,
    required this.repNameController,
    required this.repMobileController,
  });

  final CollectionDraft draft;
  final CollectDraftNotifier notifier;
  final TextEditingController repNameController;
  final TextEditingController repMobileController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CaptureTile(
              imagePath: draft.repPhotoPath,
              icon: const Icon(Icons.person_outline, size: 22, color: AppColors.goldLink),
              label: '',
              size: 62,
              circular: true,
              onTap: notifier.captureRepPhoto,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Photo of representative', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    draft.repPhotoPath != null
                        ? 'Photo captured. Tap to retake.'
                        : 'Tap the frame to open the camera. Gallery uploads are not allowed.',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        TextField(
          controller: repNameController,
          onChanged: notifier.setRepName,
          decoration: const InputDecoration(hintText: 'Full name'),
        ),
        if (draft.nameFromOcr) ...[
          const SizedBox(height: 6),
          const Text(
            'Auto-filled from Emirates ID scan',
            style: TextStyle(fontSize: 10.5, color: AppColors.success, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 9),
        Container(
          height: 47,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black.withValues(alpha: 0.16)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5EF),
                  border: Border(right: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), bottomLeft: Radius.circular(11)),
                ),
                child: const Text('+971', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF3A4552))),
              ),
              Expanded(
                child: TextField(
                  controller: repMobileController,
                  keyboardType: TextInputType.number,
                  onChanged: notifier.setRepMobile,
                  decoration: const InputDecoration(
                    hintText: '50 123 4567',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (draft.repMobile.isNotEmpty && !draft.isMobileValid) ...[
          const SizedBox(height: 6),
          const Text(
            'Enter a 9-digit UAE mobile number, e.g. 50 123 4567.',
            style: TextStyle(fontSize: 10.5, color: AppColors.danger, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

class _EmiratesIdStep extends StatelessWidget {
  const _EmiratesIdStep({required this.draft, required this.notifier});

  final CollectionDraft draft;
  final CollectDraftNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final scan = draft.idScan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Camera only — capture the front to read the ID automatically, then the back.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.45),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CaptureTile(
                imagePath: draft.idFrontPath,
                icon: const Icon(Icons.badge_outlined, size: 24, color: AppColors.goldLink),
                label: 'Capture front',
                filledLabel: 'FRONT ATTACHED',
                aspectRatio: 1.58,
                scanning: draft.isScanningId,
                onTap: notifier.captureIdFront,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CaptureTile(
                imagePath: draft.idBackPath,
                icon: const Icon(Icons.badge_outlined, size: 24, color: AppColors.goldLink),
                label: 'Capture back',
                filledLabel: 'BACK ATTACHED',
                aspectRatio: 1.58,
                scanning: draft.isScanningId,
                onTap: notifier.captureIdBack,
              ),
            ),
          ],
        ),
        if (draft.isScanningId) ...[
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            decoration: BoxDecoration(color: AppColors.pendingBg, borderRadius: BorderRadius.circular(11)),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldLink),
                ),
                const SizedBox(width: 9),
                const Text(
                  'Reading Emirates ID (OCR)…',
                  style: TextStyle(fontSize: 11.5, color: AppColors.goldLink, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
        if (scan != null && !draft.isScanningId) ...[
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF4FBF7),
              border: Border.all(color: const Color(0xFFCDEADB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('✓', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Read from ID · ${scan.confidence} confidence',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.success),
                      ),
                    ),
                    TextButton(
                      onPressed: notifier.rescanId,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: const Text(
                        'Re-scan',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLink, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    _OcrField(label: 'NAME AS PER ID', value: scan.name),
                    const SizedBox(width: 10),
                    _OcrField(label: 'ID NUMBER', value: scan.idNumber, monospace: true),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    _OcrField(label: 'NATIONALITY', value: scan.nationality),
                    const SizedBox(width: 10),
                    _OcrField(label: 'EXPIRY', value: scan.expiry),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _OcrField extends StatelessWidget {
  const _OcrField({required this.label, required this.value, this.monospace = false});

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: monospace ? 'monospace' : null),
          ),
        ],
      ),
    );
  }
}

class _ChequeStep extends StatelessWidget {
  const _ChequeStep({
    required this.draft,
    required this.notifier,
    required this.numberController,
    required this.amountController,
  });

  final CollectionDraft draft;
  final CollectDraftNotifier notifier;
  final TextEditingController numberController;
  final TextEditingController amountController;

  @override
  Widget build(BuildContext context) {
    final scan = draft.chequeScan;
    final scanning = draft.chequeOcrStatus == ChequeOcrStatus.scanning;
    final done = draft.chequeOcrStatus == ChequeOcrStatus.done;
    final rejected = draft.chequeOcrStatus == ChequeOcrStatus.rejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AED and USD cheques only — the copy is scanned and the currency verified automatically.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.45),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: numberController,
          onChanged: notifier.setChequeNumber,
          style: const TextStyle(fontFamily: 'monospace'),
          decoration: const InputDecoration(hintText: 'Cheque no.'),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F2EC),
                border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  _CurrencyChip(label: 'AED', active: draft.chequeCurrency == 'AED', onTap: () => notifier.setChequeCurrency('AED')),
                  const SizedBox(width: 4),
                  _CurrencyChip(label: 'USD', active: draft.chequeCurrency == 'USD', onTap: () => notifier.setChequeCurrency('USD')),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: amountController,
                onChanged: notifier.setChequeAmount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Amount'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CaptureTile(
          imagePath: rejected ? null : draft.chequeCopyPath,
          icon: const Icon(Icons.receipt_long_outlined, size: 22, color: AppColors.goldLink),
          label: 'Open camera to capture cheque copy',
          filledLabel: 'CHEQUE COPY CAPTURED',
          aspectRatio: 2.35,
          scanning: scanning,
          onTap: notifier.captureChequeCopy,
        ),
        if (scanning) ...[
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            decoration: BoxDecoration(color: AppColors.pendingBg, borderRadius: BorderRadius.circular(11)),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldLink),
                ),
                const SizedBox(width: 9),
                const Text(
                  'Reading cheque (OCR)…',
                  style: TextStyle(fontSize: 11.5, color: AppColors.goldLink, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
        if (done && scan != null) ...[
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF4FBF7),
              border: Border.all(color: const Color(0xFFCDEADB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('✓', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Read from cheque · ${scan.confidence} confidence',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.success),
                      ),
                    ),
                    TextButton(
                      onPressed: notifier.rescanCheque,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: const Text(
                        'Re-scan',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLink, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                _ChequeOcrRow(label: 'Drawee bank', value: scan.bank ?? '—'),
                _ChequeOcrRow(label: 'Currency', value: draft.chequeCurrency),
                _ChequeOcrRow(
                  label: 'Amount',
                  value: NumberFormat.currency(locale: 'en_US', symbol: '${draft.chequeCurrency} ', decimalDigits: 0)
                      .format(draft.amountValue),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Cheque no., amount and currency above were filled from this read — edit if the scan is off.',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
        if (rejected && scan != null) ...[
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF0EF),
              border: Border.all(color: const Color(0xFFF3CFCB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currency not accepted — ${scan.detectedCurrency} detected',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.danger),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Only AED and USD cheques can be recorded. Return this cheque to the vendor and capture an accepted one.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF3A4552), height: 1.5),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: notifier.recaptureCheque,
                    child: const Text('Capture another cheque'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: active ? AppColors.ink : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Text(
          label,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: active ? AppColors.gold : AppColors.textFaint),
        ),
      ),
    );
  }
}

class _ChequeOcrRow extends StatelessWidget {
  const _ChequeOcrRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _VoucherStep extends StatelessWidget {
  const _VoucherStep({required this.draft, required this.notifier});

  final CollectionDraft draft;
  final CollectDraftNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final voucherPath = draft.voucherPath;
    final hasVoucher = voucherPath != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Optional — capture the payment voucher for the record.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.45),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: notifier.captureVoucher,
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(color: hasVoucher ? const Color(0xFF05744F) : Colors.black.withValues(alpha: 0.2), width: 1.5),
              borderRadius: BorderRadius.circular(11),
              color: hasVoucher ? const Color(0xFFEEF8F2) : const Color(0xFFFBFAF6),
            ),
            child: hasVoucher
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(voucherPath), fit: BoxFit.cover),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 7),
                            color: Colors.black.withValues(alpha: 0.62),
                            child: const Text(
                              'VOUCHER ATTACHED · TAP TO RETAKE',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera_outlined, size: 24, color: AppColors.goldLink),
                        SizedBox(height: 8),
                        Text(
                          'Open camera to capture voucher',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Text('Supporting documents', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            const Spacer(),
            const Text('Optional', style: TextStyle(fontSize: 10.5, color: AppColors.textFaint, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final path in draft.supportingDocPaths)
              _SupportingDocThumb(path: path, onRemove: () => notifier.removeSupportingDocument(path)),
            _AddSupportingDocTile(onTap: notifier.addSupportingDocument),
          ],
        ),
        const SizedBox(height: 9),
        const Text(
          'Optional — invoices, delivery notes or anything else Finance should see.',
          style: TextStyle(fontSize: 10, color: AppColors.textFaint, height: 1.4),
        ),
      ],
    );
  }
}

class _SupportingDocThumb extends StatelessWidget {
  const _SupportingDocThumb({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.file(File(path), width: 74, height: 74, fit: BoxFit.cover),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.ink),
                alignment: Alignment.center,
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSupportingDocTile extends StatelessWidget {
  const _AddSupportingDocTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withValues(alpha: 0.2), width: 1.5),
          borderRadius: BorderRadius.circular(11),
          color: const Color(0xFFFBFAF6),
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 18, color: AppColors.goldLink),
            SizedBox(height: 2),
            Text('Add', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _ConsentStep extends StatelessWidget {
  const _ConsentStep({required this.draft, required this.notifier});

  final CollectionDraft draft;
  final CollectDraftNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final vendorName = draft.vendor?.name ?? 'the vendor';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I confirm I am the authorised representative of $vendorName collecting this cheque on its behalf, '
          'and I consent to my Emirates ID, photograph and contact details being stored for identity '
          'verification and audit of this transaction.',
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF3A4552), height: 1.6),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: notifier.toggleConsent,
          child: Row(
            children: [
              Container(
                width: 21,
                height: 21,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: draft.consent ? null : Border.all(color: Colors.black.withValues(alpha: 0.28), width: 1.5),
                  color: draft.consent ? AppColors.success : Colors.white,
                ),
                child: draft.consent
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              const Text('I have read and I consent', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignatureStep extends StatelessWidget {
  const _SignatureStep({required this.draft, required this.notifier});

  final CollectionDraft draft;
  final CollectDraftNotifier notifier;

  Future<void> _sign(BuildContext context) async {
    final bytes = await SignatureSheet.show(context);
    if (bytes != null) await notifier.setSignature(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final path = draft.signaturePath;
    final signed = path != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _sign(context),
          child: Container(
            height: 132,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: signed ? const Color(0xFF05744F) : Colors.black.withValues(alpha: 0.22)),
              borderRadius: BorderRadius.circular(12),
              color: signed ? const Color(0xFFEEF8F2) : const Color(0xFFFBFAF6),
            ),
            child: signed
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(path), fit: BoxFit.contain),
                  )
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.draw_outlined, size: 22, color: AppColors.textFaint),
                        SizedBox(height: 6),
                        Text('Tap to sign', style: TextStyle(color: AppColors.textFaint, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            if (signed)
              TextButton(
                onPressed: () => _sign(context),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('Re-sign', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF3A4552))),
              ),
            const Spacer(),
            const Text('Timestamped & sent to web portal', style: TextStyle(fontSize: 10, color: AppColors.textFaint)),
          ],
        ),
      ],
    );
  }
}

class _CollectionSuccessView extends ConsumerWidget {
  const _CollectionSuccessView({required this.record});

  final CollectionRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 34, 22, 22),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.successBg),
              alignment: Alignment.center,
              child: const Icon(Icons.check, color: AppColors.success, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Collection recorded', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19)),
            const SizedBox(height: 5),
            Text(record.ref, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Text(record.vendorName, style: const TextStyle(fontSize: 12.5, color: Color(0xFF3A4552)), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChecklistLine(text: 'Pushed to the web application tracker'),
                  SizedBox(height: 11),
                  _ChecklistLine(text: 'Emirates ID, photo, cheque copy & signature attached'),
                  SizedBox(height: 11),
                  _ChecklistLine(text: 'Signature visible to Finance for approval'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppPrimaryButton(
              label: 'Record another',
              onPressed: () => ref.read(lastSubmittedRecordProvider.notifier).set(null),
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(lastSubmittedRecordProvider.notifier).set(null);
                  ref.read(mainTabIndexProvider.notifier).setIndex(1);
                },
                child: const Text('View transactions'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('✓', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(width: 9),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF3A4552)))),
      ],
    );
  }
}

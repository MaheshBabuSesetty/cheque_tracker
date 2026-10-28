import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/phone_country_codes.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/responsive_content.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../cheques/domain/entities/cheque.dart';
import '../../domain/entities/collected_cheque.dart';
import '../../domain/entities/collection_draft.dart';
import '../../domain/entities/collection_record.dart';
import '../../domain/entities/vendor.dart';
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
    // Recording a collection is VRM-only server-side (both the vendor list
    // and the submit endpoint reject any other role) — gated here too so a
    // non-VRM account sees a clear reason instead of a form that will only
    // ever fail with "not authorized" partway through.
    final user = ref.watch(authProvider).value;
    if (user != null && !user.isAccounts) {
      return const _NotAuthorizedView();
    }

    final lastRecords = ref.watch(lastSubmittedRecordProvider);
    if (lastRecords != null && lastRecords.isNotEmpty) {
      return _CollectionSuccessView(records: lastRecords);
    }
    return const _CollectForm();
  }
}

class _NotAuthorizedView extends StatelessWidget {
  const _NotAuthorizedView();

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 32, color: colors.textFaint),
            const SizedBox(height: 12),
            Text(
              "Your account isn't authorized to record collections.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
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
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(collectDraftProvider);
    _repNameController.text = draft.repName;
    _repMobileController.text = draft.repMobile;
  }

  @override
  void dispose() {
    _repNameController.dispose();
    _repMobileController.dispose();
    super.dispose();
  }

  Future<void> _confirmSubmit() async {
    final colors = context.semanticColors;
    final count = ref.read(collectDraftProvider).cheques.length;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(count == 1 ? 'Submit this collection?' : 'Submit this collection of $count cheques?'),
        content: Text(
          "This sends the ${count == 1 ? 'cheque' : 'cheques'}, Emirates ID, photos and signature to the web record. You won't be able to edit it from here afterwards.",
          style: TextStyle(fontSize: 13, color: colors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes, submit', style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _handleSubmit();
  }

  Future<void> _handleSubmit() async {
    setState(() => _submitting = true);
    final outcome = await ref.read(collectDraftProvider.notifier).submit();
    if (!mounted) return;
    setState(() => _submitting = false);
    if (outcome == null) return;
    final records = outcome.records;
    if (records != null) {
      ref.read(lastSubmittedRecordProvider.notifier).set(records);
    } else if (outcome.error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(outcome.error!), duration: const Duration(seconds: 8)));
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
    });

    final draft = ref.watch(collectDraftProvider);
    final notifier = ref.read(collectDraftProvider.notifier);
    final done = draft.stepsDone;
    final doneCount = done.where((d) => d).length;
    final ready = draft.isComplete;
    final colors = context.semanticColors;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
          decoration: BoxDecoration(
            color: colors.pageBackground,
            border: Border(bottom: BorderSide(color: colors.hairline)),
          ),
          child: ResponsiveContent(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        'New collection',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontSize: 18),
                      ),
                    ),
                    Text(
                      '$doneCount OF 6 COMPLETE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: colors.accent,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                StepProgressBar(progress: doneCount / 6),
              ],
            ),
          ),
        ),
        Expanded(
          child: ResponsiveContent(
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
                  title: 'Emirates ID',
                  done: done[1],
                  child: _EmiratesIdStep(draft: draft, notifier: notifier),
                ),
                StepCard(
                  number: 3,
                  title: 'Representative',
                  done: done[2],
                  child: _RepresentativeStep(
                    draft: draft,
                    notifier: notifier,
                    repNameController: _repNameController,
                    repMobileController: _repMobileController,
                  ),
                ),
                StepCard(
                  number: 4,
                  title: 'Cheques',
                  done: done[3],
                  child: _ChequeStep(draft: draft, notifier: notifier),
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
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 11, 15, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.surfaceBorder)),
          ),
          child: ResponsiveContent(
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
                    color: ready ? colors.success : colors.textFaint,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 9),
                AppPrimaryButton(
                  label: _submitting ? 'Submitting…' : 'Submit',
                  isLoading: _submitting,
                  onPressed: ready && !_submitting ? _confirmSubmit : null,
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                ),
              ],
            ),
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
    final colors = context.semanticColors;
    final vendor = draft.vendor;
    if (vendor != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: colors.neutralTint,
          border: Border.all(color: colors.neutralTintBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  if (vendor.code != null || vendor.trn != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (vendor.code != null) vendor.code!,
                        if (vendor.trn != null) 'TRN ${vendor.trn}',
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: notifier.clearVendor,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: Text(
                'Change',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textMuted,
                  decoration: TextDecoration.underline,
                ),
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
              color: colors.surface,
              border: Border.all(color: colors.inputBorder),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Search vendor master…',
                    style: TextStyle(color: colors.textFaint, fontSize: 14),
                  ),
                ),
                Icon(Icons.search, size: 18, color: colors.textFaint),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          vendorCount != null
              ? 'Synced from the web master · $vendorCount active vendors'
              : 'Synced from the web master',
          style: TextStyle(fontSize: 10.5, color: colors.textFaint),
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
    final colors = context.semanticColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: repNameController,
          onChanged: notifier.setRepName,
          decoration: const InputDecoration(hintText: 'Full name'),
        ),
        if (draft.nameFromOcr) ...[
          const SizedBox(height: 6),
          Text(
            'Auto-filled from Emirates ID scan',
            style: TextStyle(
              fontSize: 10.5,
              color: colors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 9),
        Container(
          height: 47,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.inputBorder),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.placeholderBg,
                  border: Border(right: BorderSide(color: colors.hairline)),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11),
                  ),
                ),
                child: Text(
                  draft.repMobileCountryCode,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.bodyText,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: repMobileController,
                  keyboardType: TextInputType.phone,
                  onChanged: (value) => _handleMobileChanged(
                    value,
                    notifier,
                    repMobileController,
                  ),
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
          Text(
            'Enter a ${phoneCountryCodes[draft.repMobileCountryCode] ?? 9}-digit mobile number for ${draft.repMobileCountryCode}.',
            style: TextStyle(
              fontSize: 10.5,
              color: colors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  /// Splits a pasted/typed full number (e.g. "+91 98765 43210") into its
  /// country code and local digits — [notifier.setRepMobile] already does
  /// this for the draft's state, but the field's own [controller] also
  /// needs resetting to just the local part so the code isn't shown twice
  /// (once in the fixed prefix chip, once still sitting in the text).
  void _handleMobileChanged(
    String value,
    CollectDraftNotifier notifier,
    TextEditingController controller,
  ) {
    notifier.setRepMobile(value);
    final detected = detectPhoneCountryCode(value);
    if (detected != null) {
      controller.value = TextEditingValue(
        text: detected.localNumber,
        selection: TextSelection.collapsed(offset: detected.localNumber.length),
      );
    }
  }
}

class _EmiratesIdStep extends StatelessWidget {
  const _EmiratesIdStep({required this.draft, required this.notifier});

  final CollectionDraft draft;
  final CollectDraftNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final scan = draft.idScan;
    final frontFailed = draft.idFrontOcrFailed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Camera only — capture the front to read the ID automatically, then the back.',
          style: TextStyle(fontSize: 11, color: colors.textMuted, height: 1.45),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CaptureTile(
                imagePath: frontFailed ? null : draft.idFrontPath,
                icon: Icon(
                  Icons.badge_outlined,
                  size: 24,
                  color: colors.accent,
                ),
                label: frontFailed
                    ? 'Not detected — tap to retake'
                    : 'Capture front',
                filledLabel: 'FRONT READ',
                aspectRatio: 1.58,
                scanning: draft.isScanningId,
                onTap: notifier.captureIdFront,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CaptureTile(
                imagePath: draft.idBackPath,
                icon: Icon(
                  Icons.badge_outlined,
                  size: 24,
                  color: colors.accent,
                ),
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
            decoration: BoxDecoration(
              color: colors.pendingBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  'Reading Emirates ID (OCR)…',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (frontFailed && !draft.isScanningId) ...[
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: colors.dangerBg,
              border: Border.all(color: colors.dangerBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emirates ID not detected',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: colors.danger,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'The captured image is not a readable Emirates ID front. Place the card flat, fill the frame and avoid glare, then capture again.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.bodyText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: notifier.captureIdFront,
                    child: const Text('Capture front again'),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (scan != null && !draft.isScanningId && !frontFailed) ...[
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: colors.matchedBg,
              border: Border.all(color: colors.matchedBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '✓',
                      style: TextStyle(
                        color: colors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Read from ID · ${scan.confidence} confidence',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: colors.success,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: notifier.rescanId,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        'Re-scan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.accent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    _OcrField(label: 'NAME AS PER ID', value: scan.name),
                    const SizedBox(width: 10),
                    _OcrField(
                      label: 'ID NUMBER',
                      value: scan.idNumber,
                      monospace: true,
                    ),
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
  const _OcrField({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: context.semanticColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: monospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChequeStep extends StatefulWidget {
  const _ChequeStep({required this.draft, required this.notifier});

  final CollectionDraft draft;
  final CollectDraftNotifier notifier;

  @override
  State<_ChequeStep> createState() => _ChequeStepState();
}

class _ChequeStepState extends State<_ChequeStep> {
  final _manualNumberController = TextEditingController();
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Rebuilds on every keystroke so the capture button's enabled state
    // tracks whether a cheque number has been typed yet.
    _manualNumberController.addListener(_onManualNumberChanged);
  }

  @override
  void dispose() {
    _manualNumberController.removeListener(_onManualNumberChanged);
    _manualNumberController.dispose();
    super.dispose();
  }

  void _onManualNumberChanged() => setState(() {});

  /// Matches the typed number against the vendor's SIGNED cheques, then
  /// captures a photo of that cheque and adds both to the draft — no OCR is
  /// run to find the cheque. The field clears on success, ready for the
  /// next cheque.
  Future<void> _captureAndAdd(Vendor vendor) async {
    final number = _manualNumberController.text.trim();
    if (number.isEmpty) return;
    setState(() {
      _capturing = true;
      _error = null;
    });
    final result = await widget.notifier.captureAndAddCheque(vendor: vendor, number: number);
    if (!mounted) return;
    setState(() {
      _capturing = false;
      _error = switch (result) {
        ChequeAddResult.notFound => 'No SIGNED cheque on file matches that number.',
        ChequeAddResult.alreadyAdded => 'This cheque is already added to this collection.',
        ChequeAddResult.limitReached => 'A collection can include at most ${CollectionDraft.maxCheques} cheques.',
        _ => null,
      };
      if (result == ChequeAddResult.added) _manualNumberController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final draft = widget.draft;
    final notifier = widget.notifier;
    final vendor = draft.vendor;
    final entries = draft.cheques;
    final hasTypedNumber = _manualNumberController.text.trim().isNotEmpty;
    final canCapture = vendor != null && !_capturing && hasTypedNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          _ChequePhotoStep(
            key: ValueKey(entries[i].cheque.id),
            index: i + 1,
            total: entries.length,
            entry: entries[i],
            hasSharedVoucher: draft.voucherPath != null,
            notifier: notifier,
          ),
          const SizedBox(height: 12),
        ],
        if (entries.length > 1) ...[
          _ChequeTotalRow(count: entries.length, total: draft.amountValue),
          const SizedBox(height: 12),
        ],
        Text(
          vendor == null
              ? 'Pick a vendor in step 1 first.'
              : entries.isEmpty
                  ? "Type this vendor's SIGNED cheque number, then capture a photo of it."
                  : 'Collecting more than one? Type the next cheque number and capture its own photo.',
          style: TextStyle(
            fontSize: 11,
            color: colors.textMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _manualNumberController,
          textCapitalization: TextCapitalization.characters,
          enabled: vendor != null && !_capturing,
          decoration: const InputDecoration(
            isDense: true,
            hintText: 'Type the cheque number',
          ),
          onSubmitted: canCapture ? (_) => _captureAndAdd(vendor) : null,
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: canCapture ? () => _captureAndAdd(vendor) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            decoration: BoxDecoration(
              color: canCapture ? colors.neutralTint : colors.placeholderBg,
              border: Border.all(
                color: canCapture ? colors.neutralTintBorder : colors.inputBorder,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                if (_capturing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accent,
                    ),
                  )
                else
                  Icon(
                    entries.isEmpty ? Icons.photo_camera_outlined : Icons.add_a_photo_outlined,
                    size: 18,
                    color: canCapture ? colors.accent : colors.textMuted,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _capturing
                        ? 'Capturing…'
                        : entries.isEmpty
                            ? 'Capture cheque image'
                            : 'Add another cheque',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: canCapture ? colors.bodyText : colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 7),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 11,
              color: colors.danger,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

/// "N cheques · AED total" line under the cheque cards.
class _ChequeTotalRow extends StatelessWidget {
  const _ChequeTotalRow({required this.count, required this.total});

  final int count;
  final double total;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final amount = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0).format(total).trim();
    return Row(
      children: [
        Expanded(
          child: Text(
            '$count CHEQUES',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: colors.textMuted, letterSpacing: 0.3),
          ),
        ),
        Text(
          'Total AED $amount',
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// One collected cheque: its details, its own photo, and the checks run on
/// that photo. Several of these stack up when a vendor hands over more than
/// one cheque.
class _ChequePhotoStep extends StatelessWidget {
  const _ChequePhotoStep({
    super.key,
    required this.index,
    required this.total,
    required this.entry,
    required this.hasSharedVoucher,
    required this.notifier,
  });

  final int index;
  final int total;
  final CollectedCheque entry;
  final bool hasSharedVoucher;
  final CollectDraftNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final cheque = entry.cheque;
    final scanning = entry.isScanning;
    final warnings = entry.scanWarnings;
    final hasScan = !scanning && entry.scan != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.surfaceBorder),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  total > 1 ? 'CHEQUE $index OF $total · ${cheque.bank}' : cheque.bank,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => notifier.removeCheque(cheque.id),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Remove',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textMuted,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChequeInfoField(
                label: 'CHEQUE NO.',
                value: cheque.chequeNumber,
                monospace: true,
              ),
              const SizedBox(width: 10),
              _ChequeInfoField(
                label: 'AMOUNT (AED)',
                value: NumberFormat.currency(
                  locale: 'en_US',
                  symbol: '',
                  decimalDigits: 0,
                ).format(cheque.amount).trim(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => notifier.recaptureChequePhoto(cheque.id),
            child: _DashedCaptureBox(
              imagePath: entry.photoPath,
              icon: Icons.receipt_long_outlined,
              label: 'Capture or attach cheque copy',
              filledLabel: 'CHEQUE COPY CAPTURED',
            ),
          ),
          if (scanning) ...[
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              decoration: BoxDecoration(
                color: colors.pendingBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Checking cheque photo…',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (hasScan && warnings.isEmpty) ...[
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: colors.matchedBg,
                border: Border.all(color: colors.matchedBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    '✓',
                    style: TextStyle(
                      color: colors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      "Photo matches the selected cheque's vendor.",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (hasScan && warnings.isNotEmpty) ...[
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: colors.dangerBg,
                border: Border.all(color: colors.dangerBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final warning in warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        warning,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: colors.danger,
                        ),
                      ),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    "Double-check you photographed the right cheque — you can still continue if you're sure.",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.bodyText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 11),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => notifier.recaptureChequePhoto(cheque.id),
                      child: const Text('Retake photo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (entry.micrCheck != ChequeMicrCheck.pending) ...[
            const SizedBox(height: 11),
            _MicrCheckCard(entry: entry, notifier: notifier),
          ],
          const SizedBox(height: 12),
          _ChequeVoucherRow(entry: entry, hasSharedVoucher: hasSharedVoucher, notifier: notifier),
          if (entry.submitError != null) ...[
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: colors.dangerBg,
                border: Border.all(color: colors.dangerBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${entry.submitError!} Remove this cheque to submit the rest.',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: colors.danger, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Optional voucher for one cheque. Without one, the cheque gets the shared
/// voucher from step 5 (if any) — the line beside the tile says which.
class _ChequeVoucherRow extends StatelessWidget {
  const _ChequeVoucherRow({required this.entry, required this.hasSharedVoucher, required this.notifier});

  final CollectedCheque entry;
  final bool hasSharedVoucher;
  final CollectDraftNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final chequeId = entry.cheque.id;
    final voucherPath = entry.voucherPath;
    final note = voucherPath != null
        ? 'Used for this cheque instead of the shared voucher.'
        : hasSharedVoucher
            ? 'Uses the shared voucher from step 5. Add one to use a different voucher for this cheque.'
            : 'Add a voucher for this cheque, or one shared voucher in step 5.';

    return Row(
      children: [
        voucherPath != null
            ? _SupportingDocThumb(path: voucherPath, onRemove: () => notifier.removeChequeVoucher(chequeId))
            : _AddSupportingDocTile(onTap: () => notifier.captureChequeVoucher(chequeId)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Voucher',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    'Optional',
                    style: TextStyle(fontSize: 10.5, color: colors.textFaint, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(note, style: TextStyle(fontSize: 10.5, color: colors.textMuted, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Result of checking the leaf's MICR band against the selected cheque's
/// number. When the band confirms it, this is just a confirmation line;
/// when it couldn't be read, or reads a different number, the agent must
/// tick the manual-check box before step 4 counts as done.
class _MicrCheckCard extends StatelessWidget {
  const _MicrCheckCard({required this.entry, required this.notifier});

  final CollectedCheque entry;
  final CollectDraftNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final cheque = entry.cheque;
    final check = entry.micrCheck;

    if (check == ChequeMicrCheck.matched) {
      return Row(
        children: [
          Icon(Icons.verified_outlined, size: 15, color: colors.success),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Cheque no. confirmed from the MICR line.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: colors.success,
              ),
            ),
          ),
        ],
      );
    }

    final mismatched = check == ChequeMicrCheck.mismatched;
    final accent = mismatched ? colors.danger : colors.warning;
    final verified = entry.numberManuallyVerified;
    final micr = entry.scan?.micrChequeNumber;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: mismatched ? colors.dangerBg : colors.neutralTint,
        border: Border.all(
          color: mismatched ? colors.dangerBorder : colors.neutralTintBorder,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mismatched
                ? 'MICR line reads $micr — not ${cheque.chequeNumber}.'
                : "Couldn't read the MICR line on this photo.",
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Check the number printed on the cheque matches '
            '${cheque.chequeNumber}, or retake the photo with the bottom '
            'strip of the cheque in focus.',
            style: TextStyle(
              fontSize: 11.5,
              color: colors.bodyText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 11),
          GestureDetector(
            onTap: () => notifier.toggleChequeNumberVerified(cheque.id),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 21,
                  height: 21,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: verified
                        ? null
                        : Border.all(color: colors.dashedBorder, width: 1.5),
                    color: verified ? colors.success : colors.surface,
                  ),
                  child: verified
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "I've checked the cheque no. is ${cheque.chequeNumber}",
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => notifier.recaptureChequePhoto(cheque.id),
              child: const Text('Retake photo'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only display of one field from the selected [Cheque] (server
/// truth — never user-editable, unlike a real [TextField]).
class _ChequeInfoField extends StatelessWidget {
  const _ChequeInfoField({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: colors.placeholderBg,
          border: Border.all(color: colors.inputBorder),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: colors.textFaint,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dashed-bordered capture target — visually distinct from [CaptureTile]'s
/// solid border, matching the approved design's cheque-copy step
/// specifically. Shows the captured photo once [imagePath] is set.
class _DashedCaptureBox extends StatelessWidget {
  const _DashedCaptureBox({
    required this.imagePath,
    required this.icon,
    required this.label,
    required this.filledLabel,
  });

  final String? imagePath;
  final IconData icon;
  final String label;
  final String filledLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final filled = imagePath != null;
    return AspectRatio(
      aspectRatio: 2.1,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: filled ? colors.successBorder : colors.dashedBorder,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: filled ? colors.successBg : colors.placeholderBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: filled
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(imagePath!), fit: BoxFit.cover),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 7,
                          ),
                          color: Colors.black.withValues(alpha: 0.62),
                          child: Text(
                            filledLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.accent, width: 1.4),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, size: 17, color: colors.accent),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Paints a dashed rounded-rectangle outline — `BoxDecoration` has no
/// built-in dashed style, so this fills that gap for [_DashedCaptureBox].
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.4,
    this.radius = 12,
    this.dashWidth = 6,
    this.gapWidth = 5,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double gapWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}

class _VoucherStep extends StatelessWidget {
  const _VoucherStep({required this.draft, required this.notifier});

  final CollectionDraft draft;
  final CollectDraftNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final voucherPath = draft.voucherPath;
    final hasVoucher = voucherPath != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          draft.cheques.length > 1
              ? 'Optional — one voucher for every cheque. A cheque with its own voucher (added on its card) uses that instead.'
              : 'Optional — capture the payment voucher for the record.',
          style: TextStyle(fontSize: 11, color: colors.textMuted, height: 1.45),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: notifier.captureVoucher,
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(
                color: hasVoucher ? colors.successBorder : colors.dashedBorder,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(11),
              color: hasVoucher ? colors.successBg : colors.placeholderBg,
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 7,
                            ),
                            color: Colors.black.withValues(alpha: 0.62),
                            child: const Text(
                              'VOUCHER ATTACHED · TAP TO RETAKE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_camera_outlined,
                          size: 24,
                          color: colors.accent,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Open camera to capture voucher',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Text(
              'Supporting documents',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              'Optional',
              style: TextStyle(
                fontSize: 10.5,
                color: colors.textFaint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final path in draft.supportingDocPaths)
              _SupportingDocThumb(
                path: path,
                onRemove: () => notifier.removeSupportingDocument(path),
              ),
            _AddSupportingDocTile(onTap: notifier.addSupportingDocument),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          'Optional — invoices, delivery notes or anything else Finance should see.',
          style: TextStyle(fontSize: 10, color: colors.textFaint, height: 1.4),
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
            child: Image.file(
              File(path),
              width: 74,
              height: 74,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ink,
                ),
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
    final colors = context.semanticColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          border: Border.all(color: colors.dashedBorder, width: 1.5),
          borderRadius: BorderRadius.circular(11),
          color: colors.placeholderBg,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 18, color: colors.accent),
            const SizedBox(height: 2),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
              ),
            ),
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
    final colors = context.semanticColors;
    final vendorName = draft.vendor?.name ?? 'the vendor';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I confirm I am the authorised representative of $vendorName collecting ${draft.cheques.length > 1 ? 'these cheques' : 'this cheque'} on its behalf, '
          'and I consent to my Emirates ID, photograph and contact details being stored for identity '
          'verification and audit of ${draft.cheques.length > 1 ? 'these transactions' : 'this transaction'}.',
          style: TextStyle(fontSize: 11.5, color: colors.bodyText, height: 1.6),
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
                  border: draft.consent
                      ? null
                      : Border.all(color: colors.dashedBorder, width: 1.5),
                  color: draft.consent ? colors.success : colors.surface,
                ),
                child: draft.consent
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              const Text(
                'I have read and I consent',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
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
    final colors = context.semanticColors;
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
              border: Border.all(
                color: signed ? colors.successBorder : colors.dashedBorder,
              ),
              borderRadius: BorderRadius.circular(12),
              color: signed ? colors.successBg : colors.placeholderBg,
            ),
            child: signed
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(path), fit: BoxFit.contain),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.draw_outlined,
                          size: 22,
                          color: colors.textFaint,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap to sign',
                          style: TextStyle(
                            color: colors.textFaint,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Re-sign',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: colors.bodyText,
                  ),
                ),
              ),
            const Spacer(),
            Text(
              'Timestamped & sent to web portal',
              style: TextStyle(fontSize: 10, color: colors.textFaint),
            ),
          ],
        ),
      ],
    );
  }
}

class _CollectionSuccessView extends ConsumerWidget {
  const _CollectionSuccessView({required this.records});

  final List<CollectionRecord> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.semanticColors;
    final amountFormat = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 34, 22, 22),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.successBg,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.check, color: colors.success, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              records.length == 1 ? 'Collection recorded' : '${records.length} cheques recorded',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 19),
            ),
            const SizedBox(height: 5),
            Text(
              records.first.vendorName,
              style: TextStyle(fontSize: 12.5, color: colors.bodyText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            for (final record in records)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '${record.chequeNumber} · AED ${amountFormat.format(record.amount).trim()}',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.surfaceBorder),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChecklistLine(text: 'Pushed to the web application tracker'),
                  SizedBox(height: 11),
                  _ChecklistLine(
                    text:
                        'Emirates ID, photo, cheque copies & signature attached',
                  ),
                  SizedBox(height: 11),
                  _ChecklistLine(
                    text: 'Signature visible to Finance for approval',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppPrimaryButton(
              label: 'Record another',
              onPressed: () =>
                  ref.read(lastSubmittedRecordProvider.notifier).set(null),
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
    final colors = context.semanticColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '✓',
          style: TextStyle(
            color: colors.success,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: colors.bodyText),
          ),
        ),
      ],
    );
  }
}

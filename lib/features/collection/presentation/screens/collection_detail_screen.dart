import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/collection_record.dart';
import '../providers/collections_notifier.dart';
import '../widgets/status_badge.dart';

/// Read-only drill-down for one collection, reached from a transactions
/// row. Looks the record up in the already-loaded [collectionsProvider]
/// list rather than issuing a separate fetch.
class CollectionDetailScreen extends ConsumerWidget {
  const CollectionDetailScreen({super.key, required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(collectionsProvider).value ?? const <CollectionRecord>[];
    CollectionRecord? record;
    for (final r in records) {
      if (r.id == recordId) {
        record = r;
        break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: record == null
            ? const Center(child: Text('Record not found.', style: TextStyle(color: AppColors.textFaint)))
            : _DetailBody(record: record),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.record});

  final CollectionRecord record;

  @override
  Widget build(BuildContext context) {
    final tsFmt = DateFormat('dd MMM yyyy · HH:mm').format(record.timestamp);
    final amountFmt = NumberFormat.currency(locale: 'en_US', symbol: '${record.currency} ', decimalDigits: 0).format(record.amount);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
            decoration: BoxDecoration(
              color: AppColors.cream,
              border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.07))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: const Text('← All transactions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldLink)),
                ),
                const SizedBox(height: 11),
                Text(record.vendorName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17.5)),
                const SizedBox(height: 5),
                Text('${record.ref} · $tsFmt', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 20),
            child: Column(
              children: [
                _DetailCard(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('CHEQUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.4)),
                        StatusBadge(status: record.status),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Text(record.chequeNumber, style: const TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(amountFmt, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 23)),
                  ],
                ),
                const SizedBox(height: 11),
                _DetailCard(
                  children: [
                    const Text('REPRESENTATIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.4)),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Name', value: record.repName),
                    _DetailRow(label: 'Mobile', value: record.repMobile),
                    _DetailRow(label: 'Emirates ID', value: record.emiratesId),
                    _DetailRow(label: 'Nationality', value: record.nationality),
                    _DetailRow(label: 'ID expiry', value: record.expiry, isLast: true),
                  ],
                ),
                const SizedBox(height: 11),
                _DetailCard(
                  children: [
                    const Text('ATTACHMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.4)),
                    const SizedBox(height: 11),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 9,
                      crossAxisSpacing: 9,
                      childAspectRatio: 1.4,
                      children: [
                        _AttachmentTile(label: 'Rep photo', path: record.repPhotoPath),
                        _AttachmentTile(label: 'ID front', path: record.idFrontPath),
                        _AttachmentTile(label: 'ID back', path: record.idBackPath),
                        _AttachmentTile(label: 'Cheque copy', path: record.chequeCopyPath),
                        if (record.voucherPath != null) _AttachmentTile(label: 'Voucher', path: record.voucherPath),
                      ],
                    ),
                  ],
                ),
                if (record.supportingDocPaths.isNotEmpty) ...[
                  const SizedBox(height: 11),
                  _DetailCard(
                    children: [
                      const Text('SUPPORTING DOCUMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.4)),
                      const SizedBox(height: 11),
                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: [
                          for (final path in record.supportingDocPaths)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(File(path), width: 74, height: 74, fit: BoxFit.cover),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 11),
                _DetailCard(
                  children: [
                    const Text('SIGNATURE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.4)),
                    const SizedBox(height: 11),
                    Container(
                      height: 96,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black.withValues(alpha: 0.09)),
                        borderRadius: BorderRadius.circular(11),
                        color: const Color(0xFFFBFAF6),
                      ),
                      alignment: Alignment.center,
                      child: record.signaturePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(File(record.signaturePath!), fit: BoxFit.contain),
                            )
                          : const Text('Signature stored on the web record', style: TextStyle(fontSize: 11.5, color: AppColors.textFaint)),
                    ),
                    const SizedBox(height: 9),
                    Text('Captured on device · $tsFmt', style: const TextStyle(fontSize: 10.5, color: AppColors.textFaint)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.label, required this.path});

  final String label;
  final String? path;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(11),
        color: const Color(0xFFFAF8F1),
        image: path != null ? DecorationImage(image: FileImage(File(path!)), fit: BoxFit.cover) : null,
      ),
      alignment: Alignment.center,
      child: path != null
          ? null
          : Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textFaint, fontWeight: FontWeight.w600)),
    );
  }
}

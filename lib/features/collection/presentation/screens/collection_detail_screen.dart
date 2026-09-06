import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/authenticated_network_image.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/responsive_content.dart';
import '../../domain/entities/collection_record.dart';
import '../providers/collection_detail_provider.dart';

/// Read-only drill-down for one collection, reached from a transactions
/// row. The transactions list only carries the slim `CollectionSummary`
/// shape (no attachment URLs, no Emirates ID detail), so this fetches the
/// full record from `GET /collections/{chequeId}` on its own rather than
/// searching an already-loaded list.
class CollectionDetailScreen extends ConsumerWidget {
  const CollectionDetailScreen({super.key, required this.chequeId});

  final String chequeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(collectionDetailProvider(chequeId));

    return Scaffold(
      backgroundColor: context.semanticColors.pageBackground,
      body: SafeArea(
        child: recordAsync.when(
          data: (record) => _DetailBody(record: record),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Could not load this collection.',
              style: TextStyle(color: context.semanticColors.textFaint),
            ),
          ),
        ),
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
    final amountFmt = NumberFormat.currency(
      locale: 'en_US',
      symbol: '${record.currency} ',
      decimalDigits: 0,
    ).format(record.amount);
    final colors = context.semanticColors;

    return SingleChildScrollView(
      child: ResponsiveContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
              decoration: BoxDecoration(
                color: colors.pageBackground,
                border: Border(bottom: BorderSide(color: colors.hairline)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      '← All transactions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    record.vendorName,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 17.5),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${record.chequeNumber} · $tsFmt',
                    style: TextStyle(color: colors.textMuted, fontSize: 11),
                  ),
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
                          Text(
                            'CHEQUE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.textMuted,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (record.newChequeStatus != null)
                            _StatusChip(label: record.newChequeStatus!),
                        ],
                      ),
                      const SizedBox(height: 13),
                      Text(
                        record.chequeNumber,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        amountFmt,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontSize: 23),
                      ),
                      const SizedBox(height: 13),
                      SizedBox(
                        width: double.infinity,
                        height: 120,
                        child: _AttachmentTile(
                          label: 'Cheque copy',
                          url: record.chequePhotoUrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  _DetailCard(
                    children: [
                      Text(
                        'PROFILE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.textMuted,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 11),
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: _AttachmentTile(
                          label: 'Rep photo',
                          url: record.collectorPhotoUrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  _DetailCard(
                    children: [
                      Text(
                        'REPRESENTATIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.textMuted,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Name', value: record.repName),
                      _DetailRow(
                        label: 'Mobile',
                        value: record.repMobile.isEmpty
                            ? '—'
                            : record.repMobile,
                      ),
                      _DetailRow(
                        label: 'Emirates ID',
                        value: record.emiratesId.isEmpty
                            ? '—'
                            : record.emiratesId,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  _DetailCard(
                    children: [
                      Text(
                        'EMIRATES ID',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.textMuted,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 11),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 9,
                        crossAxisSpacing: 9,
                        childAspectRatio: 1.4,
                        children: [
                          _AttachmentTile(
                            label: 'ID front',
                            url: record.idFrontUrl,
                          ),
                          _AttachmentTile(
                            label: 'ID back',
                            url: record.idBackUrl,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (record.voucherUrl != null ||
                      record.supportingDocuments.isNotEmpty) ...[
                    const SizedBox(height: 11),
                    _DetailCard(
                      children: [
                        Text(
                          'VOUCHERS & DOCUMENTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Wrap(
                          spacing: 9,
                          runSpacing: 9,
                          children: [
                            if (record.voucherUrl != null)
                              _PreviewThumb(
                                url: record.voucherUrl!,
                                label: 'Voucher',
                              ),
                            for (final doc in record.supportingDocuments)
                              _PreviewThumb(
                                url: doc.url,
                                label: 'Document',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 11),
                  _DetailCard(
                    children: [
                      Text(
                        'SIGNATURE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.textMuted,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 11),
                      Container(
                        height: 96,
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.hairline),
                          borderRadius: BorderRadius.circular(11),
                          color: colors.placeholderBg,
                        ),
                        alignment: Alignment.center,
                        child: record.signatureUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: AuthenticatedNetworkImage(
                                  url: record.signatureUrl!,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : Text(
                                'Signature stored on the web record',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colors.textFaint,
                                ),
                              ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        'Collected · $tsFmt',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: colors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.successBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: colors.success,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.surfaceBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

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
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: context.semanticColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.label, required this.url});

  final String label;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    final colors = context.semanticColors;
    final tile = Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.neutralTintBorder),
        borderRadius: BorderRadius.circular(11),
        color: colors.neutralTint,
      ),
      alignment: Alignment.center,
      child: imageUrl == null
          ? Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: colors.textFaint,
                fontWeight: FontWeight.w600,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: AuthenticatedNetworkImage(
                url: imageUrl,
                fit: BoxFit.cover,
              ),
            ),
    );
    if (imageUrl == null) return tile;
    return GestureDetector(
      onTap: () => _openPhotoPreview(context, url: imageUrl, label: label),
      child: tile,
    );
  }
}

class _PreviewThumb extends StatelessWidget {
  const _PreviewThumb({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPhotoPreview(context, url: url, label: label),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 74,
          height: 74,
          child: AuthenticatedNetworkImage(url: url, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

void _openPhotoPreview(
  BuildContext context, {
  required String url,
  required String label,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => _PhotoPreviewScreen(url: url, label: label),
    ),
  );
}

class _PhotoPreviewScreen extends StatelessWidget {
  const _PhotoPreviewScreen({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(label),
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: SizedBox.expand(
          child: AuthenticatedNetworkImage(url: url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

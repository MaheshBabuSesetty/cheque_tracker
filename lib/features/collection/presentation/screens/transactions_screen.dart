import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/responsive_content.dart';
import '../../domain/entities/collection_summary.dart';
import '../providers/collections_notifier.dart';
import '../providers/transactions_filter_notifier.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider);
    final search = ref.watch(transactionsSearchProvider);
    final searchNotifier = ref.read(transactionsSearchProvider.notifier);
    final filtered = ref.watch(filteredCollectionsProvider);
    final all = collectionsAsync.value ?? const <CollectionSummary>[];
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
                        'Transactions',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontSize: 18),
                      ),
                    ),
                    Text(
                      '${all.length} recorded',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.surfaceBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16, color: colors.textFaint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: searchNotifier.set,
                          decoration: const InputDecoration(
                            hintText: 'Vendor, rep or cheque no.',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (search.isNotEmpty)
                        GestureDetector(
                          onTap: () => searchNotifier.set(''),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.hairline,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ResponsiveContent(
            child: collectionsAsync.isLoading && all.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      'Nothing matches this filter.',
                      style: TextStyle(color: colors.textFaint, fontSize: 12.5),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(15, 14, 15, 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final record = filtered[index];
                      return _TransactionRow(
                        record: record,
                        onTap: () => Navigator.of(context).pushNamed(
                          RouteNames.collectionDetail,
                          arguments: record.chequeId,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.record, required this.onTap});

  final CollectionSummary record;
  final VoidCallback onTap;

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2);
    return parts.map((p) => p[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tsFmt = DateFormat('dd MMM yyyy · HH:mm').format(record.timestamp);
    final colors = context.semanticColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.surfaceBorder),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.neutralTint,
                border: Border.all(color: colors.neutralTintBorder),
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(record.vendorName),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colors.accent,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.vendorName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.chequeNumber} · ${record.repName}',
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tsFmt,
                    style: TextStyle(fontSize: 10.5, color: colors.textFaint),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.textFaint),
          ],
        ),
      ),
    );
  }
}

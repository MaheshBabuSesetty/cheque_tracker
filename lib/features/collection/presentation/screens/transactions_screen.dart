import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
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
                    child: Text('Transactions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                  ),
                  Text('${all.length} recorded', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 16, color: AppColors.textFaint),
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
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.07)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.close, size: 12, color: AppColors.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: collectionsAsync.isLoading && all.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(
                      child: Text('Nothing matches this filter.', style: TextStyle(color: AppColors.textFaint, fontSize: 12.5)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(15, 14, 15, 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final record = filtered[index];
                        return _TransactionRow(
                          record: record,
                          onTap: () => Navigator.of(context).pushNamed(RouteNames.collectionDetail, arguments: record.chequeId),
                        );
                      },
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
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    return parts.map((p) => p[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tsFmt = DateFormat('dd MMM yyyy · HH:mm').format(record.timestamp);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 2, offset: const Offset(0, 1))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F1),
                border: Border.all(color: const Color(0xFFECDFB6)),
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(record.vendorName),
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.goldLink),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.vendorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
                  const SizedBox(height: 4),
                  Text('${record.chequeNumber} · ${record.repName}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(tsFmt, style: const TextStyle(fontSize: 10.5, color: AppColors.textFaint)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}

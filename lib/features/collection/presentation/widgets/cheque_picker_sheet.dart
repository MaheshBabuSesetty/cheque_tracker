import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../cheques/domain/entities/cheque.dart';
import '../../../cheques/presentation/providers/cheque_providers.dart';
import '../../domain/entities/vendor.dart';

/// Bottom-sheet pick of one of [vendor]'s currently-SIGNED cheques — the
/// real record a collection is submitted against
/// (`POST /cheques/{chequeId}/collection`). Mirrors [VendorPickerSheet]'s
/// shape.
class ChequePickerSheet extends ConsumerWidget {
  const ChequePickerSheet({super.key, required this.vendor});

  final Vendor vendor;

  static Future<Cheque?> show(BuildContext context, Vendor vendor) {
    return showModalBottomSheet<Cheque>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChequePickerSheet(vendor: vendor),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chequesAsync = ref.watch(signedChequesForVendorProvider(vendor));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 4,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              ),
              Text('Select a cheque', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
              const SizedBox(height: 3),
              Text(
                'SIGNED cheques on file for ${vendor.name}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: chequesAsync.when(
                  data: (cheques) {
                    if (cheques.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'This vendor has no cheque ready for collection right now.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textFaint, fontSize: 12.5, height: 1.4),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: cheques.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: Colors.black.withValues(alpha: 0.05)),
                      itemBuilder: (context, index) {
                        final cheque = cheques[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            cheque.chequeNumber,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                          ),
                          subtitle: Text(
                            '${cheque.bank} · ${NumberFormat.currency(locale: 'en_US', symbol: 'AED ', decimalDigits: 0).format(cheque.amount)}',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.goldLink, fontWeight: FontWeight.w600),
                          ),
                          onTap: () => Navigator.of(context).pop(cheque),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => const Center(child: Text('Could not load this vendor\'s cheques.')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

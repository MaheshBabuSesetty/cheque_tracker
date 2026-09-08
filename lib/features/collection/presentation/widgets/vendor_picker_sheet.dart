import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/responsive_content.dart';
import '../../domain/entities/vendor.dart';
import '../providers/collection_providers.dart';
import '../providers/vendors_provider.dart';

/// Bottom-sheet search + pick, standing in for the design's absolutely
/// positioned dropdown under the vendor field — a modal sheet is the more
/// natural Flutter idiom for "search a long master list on a small screen".
class VendorPickerSheet extends ConsumerStatefulWidget {
  const VendorPickerSheet({super.key});

  static Future<Vendor?> show(BuildContext context) {
    return showModalBottomSheet<Vendor>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VendorPickerSheet(),
    );
  }

  @override
  ConsumerState<VendorPickerSheet> createState() => _VendorPickerSheetState();
}

class _VendorPickerSheetState extends ConsumerState<VendorPickerSheet> {
  final _controller = TextEditingController();
  String _query = '';
  bool _syncing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Manual "refresh" action — forces a network re-sync of the vendor
  /// master (bypassing whatever's cached) rather than waiting for the
  /// next login, then invalidates [vendorsProvider] so this sheet's list
  /// reads the freshly-cached result without a second network round trip.
  Future<void> _refresh() async {
    setState(() => _syncing = true);
    try {
      await ref.read(syncVendorsProvider)();
    } catch (_) {
      // Keep whatever was already cached/shown — the sheet's own
      // `vendorsAsync.when(error: ...)` branch handles a first-ever sync
      // failing outright; a failed *re*-sync just leaves the list as-is.
    }
    ref.invalidate(vendorsProvider);
    if (mounted) setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(vendorsProvider);
    final colors = context.semanticColors;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.pageBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: ResponsiveContent(
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.dashedBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search vendor master…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: IconButton(
                      tooltip: 'Sync vendor master',
                      icon: _syncing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.accent,
                              ),
                            )
                          : Icon(Icons.sync, size: 20, color: colors.accent),
                      onPressed: _syncing ? null : _refresh,
                    ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: vendorsAsync.when(
                    data: (vendors) {
                      final query = _query.trim().toLowerCase();
                      final results = query.isEmpty
                          ? vendors
                          : vendors
                                .where(
                                  (v) =>
                                      v.name.toLowerCase().contains(query) ||
                                      (v.code?.toLowerCase().contains(query) ??
                                          false),
                                )
                                .toList();

                      if (results.isEmpty) {
                        return Center(
                          child: Text(
                            'No vendor in master matches that.',
                            style: TextStyle(
                              color: colors.textFaint,
                              fontSize: 12.5,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: results.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: colors.hairline),
                        itemBuilder: (context, index) {
                          final vendor = results[index];
                          final subtitleParts = [
                            if (vendor.code != null) vendor.code!,
                            if (vendor.trn != null) 'TRN ${vendor.trn}',
                          ];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              vendor.name,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: subtitleParts.isEmpty
                                ? null
                                : Text(
                                    subtitleParts.join(' · '),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.textFaint,
                                      letterSpacing: 0.02,
                                    ),
                                  ),
                            onTap: () => Navigator.of(context).pop(vendor),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => const Center(
                      child: Text('Could not load the vendor master.'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

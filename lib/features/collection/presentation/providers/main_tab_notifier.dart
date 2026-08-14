import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main_tab_notifier.g.dart';

/// Drives the `IndexedStack` in `MainShellScreen` (0 = Collect, 1 =
/// Transactions) — a plain int, per the routing guidance for tab sections
/// that don't need their own navigation stack.
@riverpod
class MainTabIndexNotifier extends _$MainTabIndexNotifier {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

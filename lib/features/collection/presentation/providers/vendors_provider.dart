import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/vendor.dart';
import 'collection_providers.dart';

part 'vendors_provider.g.dart';

/// The vendor master list — synced read-only, so a plain `Future` provider
/// (rather than a `Notifier`) is enough.
@riverpod
Future<List<Vendor>> vendors(Ref ref) => ref.watch(getVendorsProvider)();

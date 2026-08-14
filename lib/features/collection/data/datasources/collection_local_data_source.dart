import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/collection_record.dart';
import '../models/collection_record_model.dart';

/// Local-only persistence for submitted collections, newest first. Talks to
/// [SharedPreferences] directly rather than through `StorageService` — this
/// storage is entirely feature-owned (Interface Segregation: the app-shell
/// `StorageService` shouldn't grow a method for every feature that persists
/// something locally).
abstract class CollectionLocalDataSource {
  Future<List<CollectionRecord>> getAll();
  Future<void> add(CollectionRecord record);
  Future<CollectionRecord?> getById(String id);
}

class CollectionLocalDataSourceImpl implements CollectionLocalDataSource {
  CollectionLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  // v2 adds `currency` to every record — bumped rather than migrated in
  // place since there's no production data yet to preserve.
  static const _key = 'collection_records_v2';

  static final _seed = [
    CollectionRecordModel(
      id: 's1',
      ref: 'COL-2026-0341',
      vendorName: 'Al Falah Building Materials LLC',
      repName: 'Rashid Kamal',
      repMobile: '+971 50 214 7732',
      emiratesId: '784-1988-4471203-1',
      nationality: 'India',
      expiry: '14 Mar 2029',
      chequeNumber: 'CHQ-100234',
      amount: 184500,
      currency: 'AED',
      status: CollectionStatus.synced,
      timestamp: DateTime(2026, 8, 5, 11, 47),
    ),
    CollectionRecordModel(
      id: 's2',
      ref: 'COL-2026-0338',
      vendorName: 'Al Reem Facilities Services',
      repName: 'Ali Mansour',
      repMobile: '+971 55 902 4418',
      emiratesId: '784-1990-5528817-5',
      nationality: 'Egypt',
      expiry: '02 Sep 2027',
      chequeNumber: 'CHQ-100237',
      amount: 62300,
      currency: 'AED',
      status: CollectionStatus.synced,
      timestamp: DateTime(2026, 8, 4, 10, 5),
    ),
    CollectionRecordModel(
      id: 's3',
      ref: 'COL-2026-0335',
      vendorName: 'Precision Formwork Systems',
      repName: 'K. Nair',
      repMobile: '+971 56 371 2280',
      emiratesId: '784-1985-3390142-7',
      nationality: 'India',
      expiry: '30 Jun 2028',
      chequeNumber: 'CHQ-100244',
      amount: 297000,
      currency: 'USD',
      status: CollectionStatus.pending,
      timestamp: DateTime(2026, 8, 2, 9, 40),
    ),
  ];

  List<CollectionRecordModel> _read() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _write(_seed);
      return _seed;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => CollectionRecordModel.fromJson(e as Map<String, dynamic>)).toList();
    } on FormatException {
      return _seed;
    }
  }

  Future<void> _write(List<CollectionRecord> records) async {
    final models = records.map((r) => CollectionRecordModel.fromEntity(r)).toList();
    await _prefs.setString(_key, jsonEncode(models.map((m) => m.toJson()).toList()));
  }

  @override
  Future<List<CollectionRecord>> getAll() async => _read();

  @override
  Future<void> add(CollectionRecord record) async {
    final current = _read();
    await _write([record, ...current]);
  }

  @override
  Future<CollectionRecord?> getById(String id) async {
    for (final record in _read()) {
      if (record.id == id) return record;
    }
    return null;
  }
}

import 'package:cheque_tracker/features/collection/data/models/collection_record_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> json({Map<String, dynamic> extra = const {}}) => {
        'id': 'col-1',
        'chequeId': 'chq-1',
        'chequeNumber': '100234',
        'supplierName': 'Al Falah',
        'amount': 1000,
        'collectorName': 'Rashid Kamal',
        'collectedAt': '2026-10-23T08:00:00Z',
        ...extra,
      };

  test('a single-cheque record has no batch', () {
    final record = CollectionRecordModel.fromJson(json(extra: {'batchId': null, 'batchCheques': []}));
    expect(record.batchId, isNull);
    expect(record.batchCheques, isEmpty);
  });

  test('an older response without batch fields still parses', () {
    expect(CollectionRecordModel.fromJson(json()).batchCheques, isEmpty);
  });

  test('parses the other cheques collected in the same batch', () {
    final record = CollectionRecordModel.fromJson(json(extra: {
      'batchId': 'batch-1',
      'batchCheques': [
        {'chequeId': 'chq-2', 'chequeNumber': '100235', 'amount': 500.5, 'currency': 'AED'},
      ],
    }));
    expect(record.batchId, 'batch-1');
    expect(record.batchCheques.single.chequeNumber, '100235');
    expect(record.batchCheques.single.amount, 500.5);
  });
}

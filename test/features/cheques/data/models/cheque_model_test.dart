import 'package:cheque_tracker/features/cheques/data/models/cheque_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> listItem({Object? chequeType = 'Non-Nego'}) => {
        'id': 'chq-1',
        'serialNumber': 100234,
        'vendorId': 'v1',
        'supplierName': 'ACCESS SYSTEMS ELECTROMECHNICAL EQUIPMENTS LLC',
        'chequeType': chequeType,
        'paymentType': 'STND',
        'bank': 'Emirates NBD',
        'chequeNumber': '83801',
        'chequeDate': '2026-08-27T00:00:00Z',
        'amount': 30429.00,
        'signedBy': 'Noor Mohamed Ismail',
        'status': 'SIGNED',
      };

  test('parses a cheque with its type', () {
    expect(ChequeModel.fromJson(listItem()).chequeType, 'Non-Nego');
  });

  test('a cheque with no type set parses with an empty type', () {
    final cheque = ChequeModel.fromJson(listItem(chequeType: null));

    expect(cheque.chequeType, '');
    expect(cheque.chequeNumber, '83801');
  });
}

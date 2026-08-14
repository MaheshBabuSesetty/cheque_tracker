import 'package:cheque_tracker/features/collection/domain/entities/collection_draft.dart';
import 'package:cheque_tracker/features/collection/domain/entities/emirates_id_scan.dart';
import 'package:cheque_tracker/features/collection/domain/entities/vendor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vendor = Vendor(id: 'v1', name: 'Al Falah Building Materials LLC', code: 'VND-0114', trn: '100234567800003');
  const scan = EmiratesIdScan(idNumber: '784-1991-1234567-3', name: 'A', nationality: 'India', expiry: '2029', confidence: '97%');

  test('an empty draft is missing every step', () {
    const draft = CollectionDraft();

    expect(draft.isComplete, isFalse);
    expect(draft.stepsDone, [false, false, false, false, false, false]);
    expect(draft.missingStepNames, CollectionDraft.stepNames);
  });

  test('isComplete is true only once every step is satisfied', () {
    final draft = const CollectionDraft().copyWith(
      vendor: () => vendor,
      repName: 'Rashid Kamal',
      repMobile: '501234567',
      repPhotoPath: () => '/tmp/rep.jpg',
      idFrontPath: () => '/tmp/front.jpg',
      idBackPath: () => '/tmp/back.jpg',
      frontIdScan: () => scan,
      chequeNumber: 'CHQ-1',
      chequeAmount: '5000',
      chequeCopyPath: () => '/tmp/cheque.jpg',
      consent: true,
      signaturePath: () => '/tmp/signature.png',
    );

    expect(draft.stepsDone, [true, true, true, true, true, true]);
    expect(draft.missingStepNames, isEmpty);
    expect(draft.isComplete, isTrue);
  });

  test('a cheque still mid-scan or rejected keeps step 4 incomplete', () {
    final base = const CollectionDraft().copyWith(
      chequeNumber: 'CHQ-1',
      chequeAmount: '5000',
      chequeCopyPath: () => '/tmp/cheque.jpg',
    );

    expect(base.copyWith(chequeOcrStatus: ChequeOcrStatus.scanning).stepsDone[3], isFalse);
    expect(base.copyWith(chequeOcrStatus: ChequeOcrStatus.rejected).stepsDone[3], isFalse);
    expect(base.copyWith(chequeOcrStatus: ChequeOcrStatus.done).stepsDone[3], isTrue);
  });

  test('an invalid mobile number keeps the representative step incomplete', () {
    final draft = const CollectionDraft().copyWith(
      repName: 'Rashid Kamal',
      repMobile: '12', // not 9 digits
      repPhotoPath: () => '/tmp/rep.jpg',
    );

    expect(draft.isMobileValid, isFalse);
    expect(draft.stepsDone[1], isFalse);
    expect(draft.missingStepNames, contains('representative details'));
  });

  test('amountValue strips non-numeric characters from chequeAmount', () {
    const draft = CollectionDraft(chequeAmount: 'AED 184,500');
    expect(draft.amountValue, 184500);
  });

  test('setting repName manually is expected to clear nameFromOcr via copyWith', () {
    final autoFilled = const CollectionDraft().copyWith(repName: 'Ahmed', nameFromOcr: true);
    expect(autoFilled.nameFromOcr, isTrue);

    final edited = autoFilled.copyWith(repName: 'Someone Else', nameFromOcr: false);
    expect(edited.nameFromOcr, isFalse);
    expect(edited.repName, 'Someone Else');
  });
}

import 'package:cheque_tracker/features/cheques/domain/entities/cheque.dart';
import 'package:cheque_tracker/features/collection/domain/entities/cheque_scan.dart';
import 'package:cheque_tracker/features/collection/domain/entities/collection_draft.dart';
import 'package:cheque_tracker/features/collection/domain/entities/emirates_id_scan.dart';
import 'package:cheque_tracker/features/collection/domain/entities/vendor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vendor = Vendor(id: 'v1', name: 'Al Falah Building Materials LLC', code: 'VND-0114', trn: '100234567800003');
  const scan = EmiratesIdScan(idNumber: '784-1991-1234567-3', name: 'A', confidence: '97%');
  final cheque = Cheque(
    id: 'chq-1',
    serialNumber: 100234,
    vendorId: vendor.id,
    supplierName: vendor.name,
    chequeType: 'Non-Nego',
    paymentType: 'STND',
    bank: 'ENBD',
    chequeNumber: 'CHQ-100234',
    chequeDate: DateTime(2026, 7, 25),
    amount: 184500,
    signedBy: 'M. Al Suwaidi',
    status: 'SIGNED',
  );

  test('an empty draft is missing every step', () {
    const draft = CollectionDraft();

    expect(draft.isComplete, isFalse);
    expect(draft.stepsDone, [false, false, false, false, false, false]);
    expect(draft.missingStepNames, CollectionDraft.stepNames);
  });

  test('isComplete is true only once every step is satisfied', () {
    final draft = CollectionDraft().copyWith(
      vendor: () => vendor,
      repName: 'Rashid Kamal',
      repMobile: '501234567',
      repPhotoPath: () => '/tmp/rep.jpg',
      idFrontPath: () => '/tmp/front.jpg',
      idBackPath: () => '/tmp/back.jpg',
      frontIdScan: () => scan,
      cheque: () => cheque,
      chequeCopyPath: () => '/tmp/cheque.jpg',
      consent: true,
      signaturePath: () => '/tmp/signature.png',
    );

    expect(draft.stepsDone, [true, true, true, true, true, true]);
    expect(draft.missingStepNames, isEmpty);
    expect(draft.isComplete, isTrue);
  });

  test('step 4 is incomplete without a selected cheque even with a photo captured', () {
    final draft = CollectionDraft().copyWith(chequeCopyPath: () => '/tmp/cheque.jpg');
    expect(draft.stepsDone[3], isFalse);
  });

  test('step 4 is incomplete while the cheque copy is being scanned, but a mismatched vendor name does not block it', () {
    final base = CollectionDraft().copyWith(cheque: () => cheque, chequeCopyPath: () => '/tmp/cheque.jpg');

    expect(base.copyWith(isScanningChequeCopy: true).stepsDone[3], isFalse);
    expect(
      base.copyWith(
        chequeScan: () => const ChequeScan(detectedCurrency: 'AED', accepted: true, nameMatched: false),
      ).stepsDone[3],
      isTrue,
    );
  });

  test('chequeScanWarnings flags a vendor name OCR could not find, non-blocking', () {
    final draft = CollectionDraft().copyWith(
      cheque: () => cheque,
      chequeCopyPath: () => '/tmp/cheque.jpg',
      chequeScan: () => const ChequeScan(detectedCurrency: 'AED', accepted: true, nameMatched: false),
    );

    expect(draft.chequeScanWarnings, isNotEmpty);
    expect(draft.stepsDone[3], isTrue);
  });

  test('chequeScanWarnings is empty once the vendor name matches', () {
    final draft = CollectionDraft().copyWith(
      cheque: () => cheque,
      chequeCopyPath: () => '/tmp/cheque.jpg',
      chequeScan: () => const ChequeScan(detectedCurrency: 'AED', accepted: true, nameMatched: true),
    );

    expect(draft.chequeScanWarnings, isEmpty);
  });

  test('an invalid mobile number keeps the representative step incomplete', () {
    final draft = CollectionDraft().copyWith(
      repName: 'Rashid Kamal',
      repMobile: '12', // not 9 digits
      repPhotoPath: () => '/tmp/rep.jpg',
    );

    expect(draft.isMobileValid, isFalse);
    expect(draft.stepsDone[2], isFalse);
    expect(draft.missingStepNames, contains('representative details'));
  });

  test('amountValue reflects the selected cheque, and is 0 without one', () {
    const empty = CollectionDraft();
    expect(empty.amountValue, 0);

    final draft = CollectionDraft().copyWith(cheque: () => cheque);
    expect(draft.amountValue, 184500);
  });

  test('setting repName manually is expected to clear nameFromOcr via copyWith', () {
    final autoFilled = CollectionDraft().copyWith(repName: 'Ahmed', nameFromOcr: true);
    expect(autoFilled.nameFromOcr, isTrue);

    final edited = autoFilled.copyWith(repName: 'Someone Else', nameFromOcr: false);
    expect(edited.nameFromOcr, isFalse);
    expect(edited.repName, 'Someone Else');
  });
}

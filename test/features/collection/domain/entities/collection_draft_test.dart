import 'package:cheque_tracker/features/cheques/domain/entities/cheque.dart';
import 'package:cheque_tracker/features/collection/domain/entities/cheque_scan.dart';
import 'package:cheque_tracker/features/collection/domain/entities/collected_cheque.dart';
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
    chequeNumber: '100234',
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

  Cheque chequeNo(String id, String number, {double amount = 1000}) => Cheque(
        id: id,
        serialNumber: 1,
        vendorId: vendor.id,
        supplierName: vendor.name,
        chequeType: 'Non-Nego',
        paymentType: 'STND',
        bank: 'ENBD',
        chequeNumber: number,
        chequeDate: DateTime(2026, 7, 25),
        amount: amount,
        status: 'SIGNED',
      );

  CollectedCheque collected(Cheque c, {ChequeScan? scan, bool scanning = false, bool verified = false}) =>
      CollectedCheque(
        cheque: c,
        photoPath: '/tmp/${c.id}.jpg',
        scan: scan,
        isScanning: scanning,
        numberManuallyVerified: verified,
      );

  const micr100234 = ChequeScan(detectedCurrency: 'AED', accepted: true, micrChequeNumber: '100234');

  test('isComplete is true only once every step is satisfied', () {
    final draft = CollectionDraft().copyWith(
      vendor: () => vendor,
      repName: 'Rashid Kamal',
      repMobile: '501234567',
      idFrontPath: () => '/tmp/front.jpg',
      idBackPath: () => '/tmp/back.jpg',
      frontIdScan: () => scan,
      cheques: [collected(cheque, scan: micr100234)],
      consent: true,
      signaturePath: () => '/tmp/signature.png',
    );

    expect(draft.stepsDone, [true, true, true, true, true, true]);
    expect(draft.missingStepNames, isEmpty);
    expect(draft.isComplete, isTrue);
  });

  group('step 4 with several cheques', () {
    final second = chequeNo('chq-2', '100235', amount: 500);
    const micr100235 = ChequeScan(detectedCurrency: 'AED', accepted: true, micrChequeNumber: '100235');

    test('is incomplete with no cheque at all', () {
      expect(const CollectionDraft().stepsDone[3], isFalse);
    });

    test('is complete once every cheque is confirmed', () {
      final draft = CollectionDraft().copyWith(
        cheques: [collected(cheque, scan: micr100234), collected(second, scan: micr100235)],
      );
      expect(draft.stepsDone[3], isTrue);
    });

    test('one unconfirmed cheque keeps the step incomplete', () {
      final draft = CollectionDraft().copyWith(
        cheques: [collected(cheque, scan: micr100234), collected(second)],
      );
      expect(draft.stepsDone[3], isFalse);
      expect(
        draft.copyWith(cheques: [draft.cheques.first, collected(second, verified: true)]).stepsDone[3],
        isTrue,
      );
    });

    test('one cheque still scanning keeps the step incomplete', () {
      final draft = CollectionDraft().copyWith(
        cheques: [collected(cheque, scan: micr100234), collected(second, scanning: true)],
      );
      expect(draft.stepsDone[3], isFalse);
    });

    test('amountValue sums every cheque, and is 0 without any', () {
      expect(const CollectionDraft().amountValue, 0);
      final draft = CollectionDraft().copyWith(cheques: [collected(cheque), collected(second)]);
      expect(draft.amountValue, 185000);
    });
  });

  group('per-cheque checks', () {
    test('a vendor name OCR could not find warns but does not block', () {
      final entry = collected(
        cheque,
        scan: const ChequeScan(detectedCurrency: 'AED', accepted: true, nameMatched: false, micrChequeNumber: '100234'),
      );
      expect(entry.scanWarnings, isNotEmpty);
      expect(entry.isDone, isTrue);
    });

    test('no warning once the vendor name matches', () {
      final entry = collected(cheque, scan: const ChequeScan(detectedCurrency: 'AED', accepted: true, nameMatched: true));
      expect(entry.scanWarnings, isEmpty);
    });

    test('MICR check is pending while scanning', () {
      expect(collected(cheque, scanning: true).micrCheck, ChequeMicrCheck.pending);
    });

    test('a matching MICR read needs no manual check', () {
      final entry = collected(cheque, scan: micr100234);
      expect(entry.micrCheck, ChequeMicrCheck.matched);
      expect(entry.needsManualNumberCheck, isFalse);
      expect(entry.isDone, isTrue);
    });

    test('ignores the zero-padding on the MICR band', () {
      final entry = collected(
        chequeNo('chq-3', '83038'),
        scan: const ChequeScan(detectedCurrency: 'AED', accepted: true, micrChequeNumber: '083038'),
      );
      expect(entry.micrCheck, ChequeMicrCheck.matched);
    });

    test('an unreadable MICR band blocks until the agent checks by hand', () {
      final entry = collected(
        cheque,
        scan: const ChequeScan(detectedCurrency: 'AED', accepted: true),
      );
      expect(entry.micrCheck, ChequeMicrCheck.notDetected);
      expect(entry.isDone, isFalse);
      expect(entry.copyWith(numberManuallyVerified: true).isDone, isTrue);
    });

    test('a failed scan is treated as an unreadable MICR band', () {
      final entry = collected(cheque);
      expect(entry.micrCheck, ChequeMicrCheck.notDetected);
      expect(entry.isDone, isFalse);
    });

    test('a MICR read of a different number also needs the manual check', () {
      final entry = collected(
        cheque,
        scan: const ChequeScan(detectedCurrency: 'AED', accepted: true, micrChequeNumber: '100235'),
      );
      expect(entry.micrCheck, ChequeMicrCheck.mismatched);
      expect(entry.isDone, isFalse);
      expect(entry.copyWith(numberManuallyVerified: true).isDone, isTrue);
    });
  });

  test('an invalid mobile number keeps the representative step incomplete', () {
    final draft = CollectionDraft().copyWith(
      repName: 'Rashid Kamal',
      repMobile: '12', // not 9 digits
    );

    expect(draft.isMobileValid, isFalse);
    expect(draft.stepsDone[2], isFalse);
    expect(draft.missingStepNames, contains('representative details'));
  });

  test('setting repName manually is expected to clear nameFromOcr via copyWith', () {
    final autoFilled = CollectionDraft().copyWith(repName: 'Ahmed', nameFromOcr: true);
    expect(autoFilled.nameFromOcr, isTrue);

    final edited = autoFilled.copyWith(repName: 'Someone Else', nameFromOcr: false);
    expect(edited.nameFromOcr, isFalse);
    expect(edited.repName, 'Someone Else');
  });
}

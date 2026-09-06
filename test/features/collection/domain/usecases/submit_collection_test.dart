import 'package:cheque_tracker/features/cheques/domain/entities/cheque.dart';
import 'package:cheque_tracker/features/collection/domain/entities/collection_draft.dart';
import 'package:cheque_tracker/features/collection/domain/entities/collection_record.dart';
import 'package:cheque_tracker/features/collection/domain/entities/emirates_id_scan.dart';
import 'package:cheque_tracker/features/collection/domain/entities/vendor.dart';
import 'package:cheque_tracker/features/collection/domain/repositories/collection_repository.dart';
import 'package:cheque_tracker/features/collection/domain/usecases/submit_collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  late MockCollectionRepository repository;
  late SubmitCollection usecase;

  const vendor = Vendor(id: 'v1', name: 'Al Falah Building Materials LLC', code: 'VND-0114', trn: '100234567800003');
  const scan = EmiratesIdScan(
    idNumber: '784-1991-1234567-3',
    name: 'Ahmed Rasheed Nazeer',
    confidence: '97%',
  );
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

  final completeDraft = CollectionDraft().copyWith(
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

  final serverRecord = CollectionRecord(
    id: 'col-1',
    chequeId: cheque.id,
    chequeNumber: cheque.chequeNumber,
    vendorName: vendor.name,
    amount: cheque.amount,
    repName: 'Rashid Kamal',
    timestamp: DateTime(2026, 8, 15),
    newChequeStatus: 'ISSUED',
  );

  setUpAll(() {
    registerFallbackValue(const CollectionDraft());
  });

  setUp(() {
    repository = MockCollectionRepository();
    usecase = SubmitCollection(repository);
  });

  test('delegates the completed draft to the repository and returns its record', () async {
    when(() => repository.submit(completeDraft)).thenAnswer((_) async => serverRecord);

    final record = await usecase(completeDraft);

    expect(record, serverRecord);
    verify(() => repository.submit(completeDraft)).called(1);
  });

  test('asserts on an incomplete draft rather than calling the repository', () {
    const incomplete = CollectionDraft();
    expect(() => usecase(incomplete), throwsA(isA<AssertionError>()));
    verifyNever(() => repository.submit(any()));
  });
}

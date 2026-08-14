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
    nationality: 'India',
    expiry: '21 Nov 2028',
    confidence: '97%',
  );

  final completeDraft = const CollectionDraft().copyWith(
    vendor: () => vendor,
    repName: 'Rashid Kamal',
    repMobile: '501234567',
    repPhotoPath: () => '/tmp/rep.jpg',
    idFrontPath: () => '/tmp/front.jpg',
    idBackPath: () => '/tmp/back.jpg',
    frontIdScan: () => scan,
    chequeNumber: 'CHQ-100234',
    chequeAmount: '184500',
    chequeCurrency: 'USD',
    chequeCopyPath: () => '/tmp/cheque.jpg',
    consent: true,
    signaturePath: () => '/tmp/signature.png',
  );

  setUpAll(() {
    registerFallbackValue(CollectionRecord(
      id: 'fallback',
      ref: 'fallback',
      vendorName: 'fallback',
      repName: 'fallback',
      repMobile: 'fallback',
      emiratesId: 'fallback',
      nationality: 'fallback',
      expiry: 'fallback',
      chequeNumber: 'fallback',
      amount: 0,
      status: CollectionStatus.pending,
      timestamp: DateTime(2026),
    ));
  });

  setUp(() {
    repository = MockCollectionRepository();
    usecase = SubmitCollection(repository);
  });

  test('builds a record from the completed draft and persists it', () async {
    when(() => repository.getAll()).thenAnswer((_) async => const []);
    when(() => repository.submit(any())).thenAnswer((invocation) async => invocation.positionalArguments.first as CollectionRecord);

    final record = await usecase(completeDraft);

    expect(record.vendorName, vendor.name);
    expect(record.repName, 'Rashid Kamal');
    expect(record.repMobile, '+971 501234567');
    expect(record.emiratesId, scan.idNumber);
    expect(record.chequeNumber, 'CHQ-100234');
    expect(record.amount, 184500);
    expect(record.currency, 'USD');
    expect(record.status, CollectionStatus.synced);
    verify(() => repository.submit(any())).called(1);
  });

  test('numbers the ref sequentially off the existing record count', () async {
    when(() => repository.getAll()).thenAnswer((_) async => List.generate(
          5,
          (i) => CollectionRecord(
            id: 'seed-$i',
            ref: 'COL-2026-034$i',
            vendorName: 'X',
            repName: 'X',
            repMobile: 'X',
            emiratesId: 'X',
            nationality: 'X',
            expiry: 'X',
            chequeNumber: 'X',
            amount: 0,
            status: CollectionStatus.synced,
            timestamp: DateTime(2026),
          ),
        ));
    when(() => repository.submit(any())).thenAnswer((invocation) async => invocation.positionalArguments.first as CollectionRecord);

    final record = await usecase(completeDraft);

    expect(record.ref, endsWith('0347'));
  });
}

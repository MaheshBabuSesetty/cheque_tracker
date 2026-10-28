import 'package:cheque_tracker/core/di/dependency_injection.dart';
import 'package:cheque_tracker/core/error/exceptions.dart';
import 'package:cheque_tracker/features/cheques/domain/entities/cheque.dart';
import 'package:cheque_tracker/features/cheques/domain/repositories/cheque_repository.dart';
import 'package:cheque_tracker/features/collection/data/datasources/bulk_collection_flag.dart';
import 'package:cheque_tracker/features/collection/domain/entities/collected_cheque.dart';
import 'package:cheque_tracker/features/collection/domain/entities/collection_draft.dart';
import 'package:cheque_tracker/features/collection/domain/entities/collection_record.dart';
import 'package:cheque_tracker/features/collection/domain/entities/emirates_id_scan.dart';
import 'package:cheque_tracker/features/collection/domain/entities/vendor.dart';
import 'package:cheque_tracker/features/collection/domain/repositories/collection_repository.dart';
import 'package:cheque_tracker/features/collection/domain/usecases/get_collection_detail.dart';
import 'package:cheque_tracker/features/collection/domain/usecases/submit_collection.dart';
import 'package:cheque_tracker/features/collection/presentation/providers/collect_draft_notifier.dart';
import 'package:cheque_tracker/features/collection/presentation/providers/collection_providers.dart';
import 'package:cheque_tracker/services/image_capture_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSubmit extends Mock implements SubmitCollection {}

class _MockChequeRepository extends Mock implements ChequeRepository {}

class _MockImages extends Mock implements ImageCaptureService {}

class _MockCollectionRepository extends Mock implements CollectionRepository {}

class _OffFlag implements BulkCollectionFlag {
  @override
  Future<bool> isEnabled() async => false;
  @override
  void markDisabled() {}
}

void main() {
  late _MockSubmit submit;
  late _MockChequeRepository cheques;
  late _MockCollectionRepository collections;
  late ProviderContainer container;

  Cheque cheque(String id, String number, {String status = 'SIGNED'}) => Cheque(
        id: id,
        serialNumber: 1,
        vendorId: 'v1',
        supplierName: 'Al Falah',
        chequeType: 'Non-Nego',
        paymentType: 'STND',
        bank: 'ENBD',
        chequeNumber: number,
        chequeDate: DateTime(2026, 7, 25),
        amount: 1000,
        status: status,
      );

  CollectionRecord record(String chequeId, String number) => CollectionRecord(
        id: 'col-$chequeId',
        chequeId: chequeId,
        chequeNumber: number,
        vendorName: 'Al Falah',
        amount: 1000,
        repName: 'Rashid Kamal',
        timestamp: DateTime(2026, 10, 23),
      );

  final completeDraft = CollectionDraft(
    vendor: const Vendor(id: 'v1', name: 'Al Falah', code: 'VND', trn: '1'),
    repName: 'Rashid Kamal',
    repMobile: '501234567',
    idFrontPath: '/tmp/front.jpg',
    idBackPath: '/tmp/back.jpg',
    frontIdScan: const EmiratesIdScan(idNumber: '784-1991-1234567-3', name: 'R', confidence: '100%'),
    cheques: [
      CollectedCheque(cheque: cheque('chq-1', '100234'), photoPath: '/tmp/c1.jpg', numberManuallyVerified: true),
      CollectedCheque(cheque: cheque('chq-2', '100235'), photoPath: '/tmp/c2.jpg', numberManuallyVerified: true),
    ],
    consent: true,
    signaturePath: '/tmp/sig.png',
  );

  CollectDraftNotifier primedNotifier() {
    final notifier = container.read(collectDraftProvider.notifier);
    // ignore: invalid_use_of_protected_member
    notifier.state = completeDraft;
    return notifier;
  }

  setUpAll(() => registerFallbackValue(const CollectionDraft()));

  setUp(() {
    submit = _MockSubmit();
    cheques = _MockChequeRepository();
    collections = _MockCollectionRepository();
    final images = _MockImages();
    when(() => images.deleteFile(any())).thenAnswer((_) async {});
    container = ProviderContainer(overrides: [
      submitCollectionProvider.overrideWithValue(submit),
      chequeRepositoryProvider.overrideWithValue(cheques),
      getCollectionDetailProvider.overrideWithValue(GetCollectionDetail(collections)),
      imageCaptureServiceProvider.overrideWithValue(images),
      bulkCollectionFlagProvider.overrideWithValue(_OffFlag()),
    ]);
    addTearDown(container.dispose);
  });

  test('success returns the records and clears the draft', () async {
    when(() => submit(any())).thenAnswer((_) async => [record('chq-1', '100234'), record('chq-2', '100235')]);
    final notifier = primedNotifier();

    final outcome = await notifier.submit();

    expect(outcome!.records, hasLength(2));
    expect(container.read(collectDraftProvider).cheques, isEmpty);
  });

  test('an error about one cheque keeps the draft and marks that cheque', () async {
    when(() => submit(any())).thenThrow(
      const ApiException(
        'Cheque 100235 is on hold.',
        statusCode: 409,
        code: 'CHEQUE_ON_HOLD',
        chequeId: 'chq-2',
        chequeNumber: '100235',
      ),
    );
    final notifier = primedNotifier();

    final outcome = await notifier.submit();

    expect(outcome!.error, 'Cheque 100235 is on hold.');
    final draft = container.read(collectDraftProvider);
    expect(draft.cheques, hasLength(2));
    expect(draft.cheques[0].submitError, isNull);
    expect(draft.cheques[1].submitError, 'Cheque 100235 is on hold.');
  });

  test('a 5xx where every cheque turns out Issued is a success', () async {
    when(() => submit(any())).thenThrow(const ApiException('Boom.', statusCode: 500));
    when(() => cheques.getChequeById(any())).thenAnswer((i) async => cheque(i.positionalArguments.first as String, '1', status: 'Issued'));
    when(() => collections.getByChequeId('chq-1')).thenAnswer((_) async => record('chq-1', '100234'));
    when(() => collections.getByChequeId('chq-2')).thenAnswer((_) async => record('chq-2', '100235'));
    final notifier = primedNotifier();

    final outcome = await notifier.submit();

    expect(outcome!.records!.map((r) => r.chequeId), unorderedEquals(['chq-1', 'chq-2']));
    expect(container.read(collectDraftProvider).cheques, isEmpty);
  });

  test('a timeout with only some cheques Issued drops those and keeps the rest', () async {
    when(() => submit(any())).thenThrow(const NetworkException());
    when(() => cheques.getChequeById('chq-1')).thenAnswer((_) async => cheque('chq-1', '100234', status: 'ISSUED'));
    when(() => cheques.getChequeById('chq-2')).thenAnswer((_) async => cheque('chq-2', '100235'));
    final notifier = primedNotifier();

    final outcome = await notifier.submit();

    expect(outcome!.error, contains('100234'));
    expect(outcome.error, contains('already collected'));
    final remaining = container.read(collectDraftProvider).cheques;
    expect(remaining.map((c) => c.cheque.id), ['chq-2']);
  });

  test('CHEQUE_ALREADY_COLLECTED on a retry is reconciled the same way', () async {
    when(() => submit(any())).thenThrow(
      const ApiException('Already collected.', statusCode: 409, code: 'CHEQUE_ALREADY_COLLECTED', chequeId: 'chq-1'),
    );
    when(() => cheques.getChequeById('chq-1')).thenAnswer((_) async => cheque('chq-1', '100234', status: 'Issued'));
    when(() => cheques.getChequeById('chq-2')).thenAnswer((_) async => cheque('chq-2', '100235'));
    final notifier = primedNotifier();

    await notifier.submit();

    expect(container.read(collectDraftProvider).cheques.map((c) => c.cheque.id), ['chq-2']);
  });

  test('a 5xx where nothing was collected leaves the draft untouched', () async {
    when(() => submit(any())).thenThrow(const ApiException('Boom.', statusCode: 500));
    when(() => cheques.getChequeById(any())).thenAnswer((i) async => cheque(i.positionalArguments.first as String, '1'));
    final notifier = primedNotifier();

    final outcome = await notifier.submit();

    expect(outcome!.error, 'Boom.');
    expect(container.read(collectDraftProvider).cheques, hasLength(2));
  });
}

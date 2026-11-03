import 'package:cheque_tracker/core/di/dependency_injection.dart';
import 'package:cheque_tracker/core/error/exceptions.dart';
import 'package:cheque_tracker/features/cheques/domain/entities/cheque.dart';
import 'package:cheque_tracker/features/cheques/domain/entities/cheque_page.dart';
import 'package:cheque_tracker/features/cheques/domain/repositories/cheque_repository.dart';
import 'package:cheque_tracker/features/collection/data/datasources/bulk_collection_flag.dart';
import 'package:cheque_tracker/features/collection/domain/entities/collected_cheque.dart';
import 'package:cheque_tracker/features/collection/domain/entities/collection_draft.dart';
import 'package:cheque_tracker/features/collection/domain/entities/emirates_id_scan.dart';
import 'package:cheque_tracker/features/collection/domain/entities/vendor.dart';
import 'package:cheque_tracker/features/collection/domain/usecases/scan_cheque.dart';
import 'package:cheque_tracker/features/collection/domain/usecases/scan_emirates_id.dart';
import 'package:cheque_tracker/features/collection/domain/usecases/submit_collection.dart';
import 'package:cheque_tracker/features/collection/presentation/providers/collect_draft_notifier.dart';
import 'package:cheque_tracker/features/collection/presentation/providers/collection_providers.dart';
import 'package:cheque_tracker/services/image_capture_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChequeRepository extends Mock implements ChequeRepository {}

class _MockImages extends Mock implements ImageCaptureService {}

class _MockScanEmiratesId extends Mock implements ScanEmiratesId {}

class _MockSubmit extends Mock implements SubmitCollection {}

class _MockScanCheque extends Mock implements ScanCheque {}

class _OffFlag implements BulkCollectionFlag {
  @override
  Future<bool> isEnabled() async => false;
  @override
  void markDisabled() {}
}

void main() {
  const vendor = Vendor(id: 'v1', name: 'ACCESS SYSTEMS ELECTROMECHNICAL', code: 'VND', trn: '1');

  late _MockChequeRepository cheques;
  late _MockImages images;
  late _MockScanEmiratesId scanId;
  late _MockSubmit submit;
  late _MockScanCheque scanCheque;
  late ProviderContainer container;

  Cheque cheque(String id, String number, {String status = 'SIGNED'}) => Cheque(
        id: id,
        serialNumber: 1,
        vendorId: 'v1',
        supplierName: 'ACCESS SYSTEMS ELECTROMECHNICAL',
        chequeType: 'Non-Nego',
        paymentType: 'STND',
        bank: 'ENBD',
        chequeNumber: number,
        chequeDate: DateTime(2026, 7, 25),
        amount: 1000,
        status: status,
      );

  void lookupThrows(Object error) {
    when(
      () => cheques.getCheques(
        search: any(named: 'search'),
        status: any(named: 'status'),
        paymentType: any(named: 'paymentType'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => throw error);
  }

  setUpAll(() => registerFallbackValue(const CollectionDraft()));

  setUp(() {
    cheques = _MockChequeRepository();
    images = _MockImages();
    scanId = _MockScanEmiratesId();
    submit = _MockSubmit();
    scanCheque = _MockScanCheque();
    when(() => scanCheque(any(), expectedPayeeName: any(named: 'expectedPayeeName'))).thenThrow(StateError('no ocr'));
    when(() => images.deleteFile(any())).thenAnswer((_) async {});
    container = ProviderContainer(overrides: [
      chequeRepositoryProvider.overrideWithValue(cheques),
      imageCaptureServiceProvider.overrideWithValue(images),
      scanEmiratesIdProvider.overrideWithValue(scanId),
      // OCR is a best-effort check, covered elsewhere; failing it here keeps
      // the real ML Kit recognizer out of these tests.
      scanChequeProvider.overrideWithValue(scanCheque),
      submitCollectionProvider.overrideWithValue(submit),
      bulkCollectionFlagProvider.overrideWithValue(_OffFlag()),
    ]);
    addTearDown(container.dispose);
  });

  group('captureAndAddCheque', () {
    test('a matching SIGNED cheque opens the camera and is added', () async {
      when(
        () => cheques.getCheques(
          search: 'ACCESS SYSTEMS ELECTROMECHNICAL',
          status: 'SIGNED',
          paymentType: any(named: 'paymentType'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => ChequePage(items: [cheque('chq-1', '87230')], totalCount: 1, page: 1, pageSize: 20));
      when(() => images.captureFromCamera(prefix: 'cheque-scan-select')).thenAnswer((_) async => '/tmp/c1.jpg');

      final result =
          await container.read(collectDraftProvider.notifier).captureAndAddCheque(vendor: vendor, number: '87230');

      expect(result, ChequeAddResult.added);
      expect(container.read(collectDraftProvider).cheques.single.cheque.chequeNumber, '87230');
    });

    test('a lookup that fails at once surfaces the real error, not a StateError', () async {
      lookupThrows(const NetworkException());

      await expectLater(
        container.read(collectDraftProvider.notifier).captureAndAddCheque(vendor: vendor, number: '87230'),
        throwsA(isA<NetworkException>()),
      );
      verifyNever(() => images.captureFromCamera(prefix: any(named: 'prefix')));
    });

    test('a lookup that fails after a delay surfaces the real error', () async {
      when(
        () => cheques.getCheques(
          search: any(named: 'search'),
          status: any(named: 'status'),
          paymentType: any(named: 'paymentType'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        throw const NetworkException();
      });

      await expectLater(
        container.read(collectDraftProvider.notifier).captureAndAddCheque(vendor: vendor, number: '87230'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('Emirates ID scan', () {
    test('a scan that throws still clears isScanningId', () async {
      when(() => images.captureFromCamera(prefix: 'id-front')).thenAnswer((_) async => '/tmp/front.jpg');
      when(() => scanId(any())).thenThrow(StateError('ml kit gone'));

      await container.read(collectDraftProvider.notifier).captureIdFront();

      final draft = container.read(collectDraftProvider);
      expect(draft.isScanningId, isFalse);
      expect(draft.idFrontPath, '/tmp/front.jpg');
    });

    test('rescan that throws still clears isScanningId', () async {
      when(() => scanId(any())).thenThrow(StateError('ml kit gone'));
      final notifier = container.read(collectDraftProvider.notifier);
      // ignore: invalid_use_of_protected_member
      notifier.state = const CollectionDraft(idFrontPath: '/tmp/front.jpg', idBackPath: '/tmp/back.jpg');

      await notifier.rescanId();

      expect(container.read(collectDraftProvider).isScanningId, isFalse);
    });
  });

  test('submit turns an unexpected error into a failed outcome and keeps the draft', () async {
    when(() => submit(any())).thenThrow(const FileSystemLikeError());
    when(() => cheques.getChequeById(any())).thenAnswer((inv) async => cheque(inv.positionalArguments.first as String, '100234'));
    final notifier = container.read(collectDraftProvider.notifier);
    final draft = CollectionDraft(
      vendor: vendor,
      repName: 'Rashid Kamal',
      repMobile: '501234567',
      idFrontPath: '/tmp/front.jpg',
      idBackPath: '/tmp/back.jpg',
      frontIdScan: const EmiratesIdScan(idNumber: '784-1991-1234567-3', name: 'R', confidence: '100%'),
      cheques: [CollectedCheque(cheque: cheque('chq-1', '100234'), photoPath: '/tmp/c1.jpg', numberManuallyVerified: true)],
      consent: true,
      signaturePath: '/tmp/sig.png',
    );
    // ignore: invalid_use_of_protected_member
    notifier.state = draft;

    final outcome = await notifier.submit();

    expect(outcome!.records, isNull);
    expect(outcome.error, "Couldn't submit this collection. Please try again.");
    expect(container.read(collectDraftProvider).cheques, hasLength(1));
  });
}

/// Stands in for anything outside the API's typed exceptions — e.g. a
/// capture file gone from disk.
class FileSystemLikeError implements Exception {
  const FileSystemLikeError();
}

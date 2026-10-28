import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cheque_tracker/core/error/exceptions.dart';
import 'package:cheque_tracker/core/network/api_error_parser.dart';
import 'package:cheque_tracker/features/cheques/domain/entities/cheque.dart';
import 'package:cheque_tracker/features/collection/data/datasources/bulk_collection_flag.dart';
import 'package:cheque_tracker/features/collection/data/datasources/collection_remote_data_source.dart';
import 'package:cheque_tracker/features/collection/domain/entities/collected_cheque.dart';
import 'package:cheque_tracker/features/collection/domain/entities/collection_draft.dart';
import 'package:cheque_tracker/features/collection/domain/entities/emirates_id_scan.dart';
import 'package:cheque_tracker/features/collection/domain/entities/vendor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves canned answers by path and records every request.
class _FakeServer implements HttpClientAdapter {
  _FakeServer({this.bulkFlag = true, this.bulkDisabledOnPost = false});

  final bool? bulkFlag;
  final bool bulkDisabledOnPost;
  final requests = <RequestOptions>[];

  Map<String, dynamic> _record(String chequeId, String number) => {
        'id': 'col-$chequeId',
        'chequeId': chequeId,
        'chequeNumber': number,
        'supplierName': 'Al Falah',
        'amount': 1000,
        'collectorName': 'Rashid Kamal',
        'collectedAt': '2026-10-23T08:00:00Z',
        'newChequeStatus': 'Issued',
      };

  ResponseBody _json(Object body, int status) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {Headers.contentTypeHeader: ['application/json']},
      );

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (options.path == '/app/version') {
      return _json({'features': {if (bulkFlag != null) 'bulkCollection': bulkFlag}}, 200);
    }
    if (options.path == '/cheques/bulk/collection') {
      if (bulkDisabledOnPost) {
        return _json({'status': 404, 'message': 'Off.', 'code': 'BULK_COLLECTION_DISABLED'}, 404);
      }
      return _json({
        'batchId': 'batch-1',
        'collections': [_record('chq-1', '100234'), _record('chq-2', '100235')],
      }, 201);
    }
    final id = RegExp(r'/cheques/(.+)/collection').firstMatch(options.path)!.group(1)!;
    return _json(_record(id, id == 'chq-1' ? '100234' : '100235'), 201);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('collection_ds_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  String photo(String name) => (File('${tmp.path}/$name.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF])).path;

  Cheque cheque(String id, String number) => Cheque(
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
        status: 'SIGNED',
      );

  CollectionDraft draft() => CollectionDraft(
        vendor: const Vendor(id: 'v1', name: 'Al Falah', code: 'VND', trn: '1'),
        repName: 'Rashid Kamal',
        repMobile: '501234567',
        idFrontPath: photo('front'),
        idBackPath: photo('back'),
        frontIdScan: const EmiratesIdScan(
          idNumber: '784-1991-1234567-3',
          name: 'R',
          confidence: '100%',
          nationality: 'India',
        ),
        cheques: [
          CollectedCheque(cheque: cheque('chq-1', '100234'), photoPath: photo('c1')),
          CollectedCheque(cheque: cheque('chq-2', '100235'), photoPath: photo('c2')),
        ],
        signaturePath: photo('sig'),
      );

  CollectionRemoteDataSourceImpl dataSource(_FakeServer server) {
    final dio = Dio()..httpClientAdapter = server;
    return CollectionRemoteDataSourceImpl(dio, BulkCollectionFlag(dio));
  }

  Map<String, String> fieldsOf(RequestOptions r) => {for (final f in (r.data as FormData).fields) f.key: f.value};
  List<String> fileKeysOf(RequestOptions r) => (r.data as FormData).files.map((f) => f.key).toList();
  Map<String, String?> fileNamesOf(RequestOptions r) => {
        for (final f in (r.data as FormData).files) f.key: f.value.filename,
      };

  /// [draft] with a shared voucher and/or a voucher on the first cheque only.
  CollectionDraft withVouchers({required bool shared, required bool onFirst}) {
    final base = draft();
    return base.copyWith(
      voucherPath: () => shared ? photo('shared-voucher') : null,
      cheques: [
        base.cheques[0].copyWith(voucherPath: () => onFirst ? photo('c1-voucher') : null),
        base.cheques[1],
      ],
    );
  }

  test('flag on: submits every cheque, each with its own photo, in one POST /cheques/bulk/collection', () async {
    final server = _FakeServer();
    final records = await dataSource(server).submit(draft());

    final post = server.requests.singleWhere((r) => r.method == 'POST');
    expect(post.path, '/cheques/bulk/collection');
    final fields = fieldsOf(post);
    expect(fields.containsKey('VendorId'), isFalse);
    expect(fields['Items[0].ChequeId'], 'chq-1');
    expect(fields['Items[1].ChequeId'], 'chq-2');
    expect(fileKeysOf(post), containsAll(['Items[0].ChequePhoto', 'Items[1].ChequePhoto', 'Signature']));
    expect(fileKeysOf(post), isNot(contains('ChequePhoto')));
    expect(records.map((r) => r.chequeId), ['chq-1', 'chq-2']);
  });

  test('bulk: a cheque\'s own voucher goes under its item, the shared one at the top level', () async {
    final server = _FakeServer();
    await dataSource(server).submit(withVouchers(shared: true, onFirst: true));

    final files = fileNamesOf(server.requests.singleWhere((r) => r.method == 'POST'));
    expect(files['AcknowledgementVoucher'], 'shared-voucher.jpg');
    expect(files['Items[0].AcknowledgementVoucher'], 'c1-voucher.jpg');
    expect(files.containsKey('Items[1].AcknowledgementVoucher'), isFalse);
  });

  test('bulk: no vouchers sends no voucher keys', () async {
    final server = _FakeServer();
    await dataSource(server).submit(draft());

    final keys = fileKeysOf(server.requests.singleWhere((r) => r.method == 'POST'));
    expect(keys.where((k) => k.contains('AcknowledgementVoucher')), isEmpty);
  });

  test('one-by-one: each cheque gets its own voucher, else the shared one, else none', () async {
    final server = _FakeServer(bulkFlag: false);
    await dataSource(server).submit(withVouchers(shared: true, onFirst: true));
    var posts = server.requests.where((r) => r.method == 'POST').toList();
    expect(fileNamesOf(posts[0])['AcknowledgementVoucher'], 'c1-voucher.jpg');
    expect(fileNamesOf(posts[1])['AcknowledgementVoucher'], 'shared-voucher.jpg');

    server.requests.clear();
    await dataSource(server).submit(withVouchers(shared: false, onFirst: true));
    posts = server.requests.where((r) => r.method == 'POST').toList();
    expect(fileNamesOf(posts[0])['AcknowledgementVoucher'], 'c1-voucher.jpg');
    expect(fileKeysOf(posts[1]), isNot(contains('AcknowledgementVoucher')));
  });

  test('sends the nationality the ID scan read, and the expiry key empty', () async {
    final server = _FakeServer();
    await dataSource(server).submit(draft());

    final fields = fieldsOf(server.requests.singleWhere((r) => r.method == 'POST'));
    expect(fields['CollectorNationality'], 'India');
    expect(fields['CollectorEidExpiryDate'], '');
  });

  for (final flag in <bool?>[false, null]) {
    test('flag ${flag ?? 'missing'}: collects one cheque at a time on the single-cheque endpoint', () async {
      final server = _FakeServer(bulkFlag: flag);
      final records = await dataSource(server).submit(draft());

      final posts = server.requests.where((r) => r.method == 'POST').toList();
      expect(posts.map((r) => r.path), ['/cheques/chq-1/collection', '/cheques/chq-2/collection']);
      for (final post in posts) {
        expect(fileKeysOf(post), containsAll(['ChequePhoto', 'Signature', 'EmiratesIdFront']));
        expect(fieldsOf(post).keys.where((k) => k.startsWith('Items')), isEmpty);
      }
      expect(records.map((r) => r.chequeId), ['chq-1', 'chq-2']);
    });
  }

  test('BULK_COLLECTION_DISABLED mid-session falls back to one-by-one and remembers it', () async {
    final server = _FakeServer(bulkDisabledOnPost: true);
    final source = dataSource(server);

    await source.submit(draft());
    expect(
      server.requests.where((r) => r.method == 'POST').map((r) => r.path),
      ['/cheques/bulk/collection', '/cheques/chq-1/collection', '/cheques/chq-2/collection'],
    );

    server.requests.clear();
    await source.submit(draft());
    expect(server.requests.where((r) => r.path == '/cheques/bulk/collection'), isEmpty);
  });

  test('the error parser keeps the code and the offending cheque', () {
    final error = ApiErrorParser.parse(
      DioException(
        requestOptions: RequestOptions(path: '/cheques/bulk/collection'),
        response: Response(
          requestOptions: RequestOptions(path: '/cheques/bulk/collection'),
          statusCode: 409,
          data: {
            'status': 409,
            'message': 'Cheque 004512 is on hold.',
            'code': 'CHEQUE_ON_HOLD',
            'chequeId': 'chq-9',
            'chequeNumber': '004512',
          },
        ),
      ),
    );

    expect(error, isA<ApiException>());
    final api = error as ApiException;
    expect(api.code, 'CHEQUE_ON_HOLD');
    expect(api.chequeId, 'chq-9');
    expect(api.statusCode, 409);
    expect(api.isServerFailure, isFalse);
  });
}

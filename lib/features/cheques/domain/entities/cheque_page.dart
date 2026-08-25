import 'package:equatable/equatable.dart';

import 'cheque.dart';

/// One page of `GET /cheques`.
class ChequePage extends Equatable {
  const ChequePage({required this.items, required this.totalCount, required this.page, required this.pageSize});

  final List<Cheque> items;
  final int totalCount;
  final int page;
  final int pageSize;

  @override
  List<Object?> get props => [items, totalCount, page, pageSize];
}

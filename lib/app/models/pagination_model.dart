// ignore_for_file: public_member_api_docs, sort_constructors_first

T? tryCast<T>(dynamic x, {T? fallback}) {
  if (x is T) return x;

  return fallback;
}

extension ObjectExtension<T> on T {
  R? let<R>(R Function(T) transform) => this != null ? transform(this!) : null;
}

class Pagination {
  Pagination({
    this.total,
    this.page = 1,
    this.limit = 10,
    this.totalPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: tryCast<int>(json['total']) ?? 0,
      page: tryCast<int>(json['page']) ?? 1,
      limit: tryCast<int>(json['limit']) ?? 10,
      totalPage: tryCast<int>(json['totalPages']) ?? 1,
    );
  }
  final int? total;
  final int page;
  final int limit;
  final int? totalPage;

  bool get hasNext => page < (totalPage ?? 1);

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'limit': limit,
      'totalPage': totalPage,
    };
  }

  Pagination copyWith({
    int? total,
    int? page,
    int? limit,
    int? totalPage,
  }) {
    return Pagination(
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPage: totalPage ?? this.totalPage,
    );
  }
}

class PaginatedResponse<T> {
  PaginatedResponse({
    required this.items,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) itemParser) {
    final items = (json['data'] as List).map((item) => itemParser(item as Map<String, dynamic>)).toList();
    final pagination = Pagination.fromJson(json['pagination'] as Map<String, dynamic>);
    return PaginatedResponse<T>(
      items: items,
      pagination: pagination,
    );
  }
  final List<T> items;
  final Pagination pagination;

  PaginatedResponse<T> copyWith({
    List<T>? items,
    Pagination? pagination,
  }) {
    return PaginatedResponse<T>(
      items: items ?? this.items,
      pagination: pagination ?? this.pagination,
    );
  }
}

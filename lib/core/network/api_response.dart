import '../json/json_utils.dart';

/// Unwraps the backend `ApiResponse<T>` envelope ({ success, message, data, ... }) and returns the
/// parsed `data` payload.
T unwrap<T>(dynamic body, T Function(dynamic data) parse) {
  final map = (body as Map).cast<String, dynamic>();
  return parse(map['data']);
}

/// Mirrors com.ls45.common.pagination.PageResponse — a page of [T].
class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    return PageResponse<T>(
      content: asModelList<T>(json['content'], itemFromJson),
      page: asInt(json['page']),
      size: asInt(json['size']),
      totalElements: asInt(json['totalElements']),
      totalPages: asInt(json['totalPages']),
      first: asBool(json['first'], true),
      last: asBool(json['last'], true),
    );
  }
}

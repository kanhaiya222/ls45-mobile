import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/core/network/api_response.dart';
import 'package:ls45_mobile/features/catalog/models/catalog_models.dart';

void main() {
  test('unwrap extracts the data payload from the ApiResponse envelope', () {
    final body = {
      'success': true,
      'data': {'publicId': 'cat-1', 'name': 'Coastal', 'slug': 'coastal'},
    };
    final category = unwrap(body, (d) => Category.fromJson((d as Map).cast<String, dynamic>()));
    expect(category.name, 'Coastal');
  });

  test('PageResponse.fromJson parses content + paging flags', () {
    final json = {
      'content': [
        {'publicId': 'p1', 'name': 'A', 'slug': 'a', 'durationDays': 5, 'durationNights': 4, 'featured': false},
        {'publicId': 'p2', 'name': 'B', 'slug': 'b', 'durationDays': 3, 'durationNights': 2, 'featured': true},
      ],
      'page': 0,
      'size': 20,
      'totalElements': 2,
      'totalPages': 1,
      'first': true,
      'last': true,
    };
    final page = PageResponse.fromJson(json, PackageSummary.fromJson);
    expect(page.content, hasLength(2));
    expect(page.content[1].featured, isTrue);
    expect(page.totalElements, 2);
    expect(page.last, isTrue);
  });
}

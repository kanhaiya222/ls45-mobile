// Small null-safe JSON coercion helpers shared by the hand-written model `fromJson` factories.
// Jackson serialises BigDecimal/Long as JSON numbers, so numeric fields arrive as `num`.

double? asDoubleOrNull(dynamic v) => v == null ? null : (v as num).toDouble();

int asInt(dynamic v, [int fallback = 0]) => v == null ? fallback : (v as num).toInt();

int? asIntOrNull(dynamic v) => v == null ? null : (v as num).toInt();

bool asBool(dynamic v, [bool fallback = false]) => v is bool ? v : fallback;

String asString(dynamic v, [String fallback = '']) =>
    v is String ? v : (v?.toString() ?? fallback);

String? asStringOrNull(dynamic v) => v is String ? v : v?.toString();

List<String>? asStringListOrNull(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : null;

/// Parses a JSON array of objects into a list of models, skipping non-object entries.
List<T> asModelList<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) => v is List
    ? v
        .whereType<Map>()
        .map((e) => fromJson(e.cast<String, dynamic>()))
        .toList(growable: false)
    : const [];

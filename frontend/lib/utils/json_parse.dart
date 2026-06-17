/// Parsing aman untuk nilai numerik dari JSON / route arguments.
int? intFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

int? intArg(Map<String, dynamic> map, String key) => intFromJson(map[key]);

int requireIntArg(Map<String, dynamic> map, String key) {
  final v = intArg(map, key);
  if (v == null) {
    throw FormatException('Argument "$key" wajib berupa angka');
  }
  return v;
}

/// ID dari API (int, num, atau string angka). Null jika tidak valid.
int? entityId(dynamic value) => intFromJson(value);

bool idEquals(dynamic a, int b) => intFromJson(a) == b;

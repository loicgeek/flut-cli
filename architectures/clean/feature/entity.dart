/// Domain entity — pure Dart. No JSON, no Flutter, no Dio: nothing here may
/// depend on how the data arrives or how it is displayed.
class {{Pascal}} {
  const {{Pascal}}({
    required this.id,
    // TODO: add fields
  });

  final String id;
  // TODO: add fields

  {{Pascal}} copyWith({
    String? id,
    // TODO: add fields
  }) {
    return {{Pascal}}(id: id ?? this.id);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is {{Pascal}} && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '{{Pascal}}(id: $id)';
}

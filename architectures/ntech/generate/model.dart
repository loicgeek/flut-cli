class {{Pascal}}Model {
  const {{Pascal}}Model({
    required this.id,
    // TODO: add fields
  });

  final String id;
  // TODO: add fields

  factory {{Pascal}}Model.fromJson(Map<String, dynamic> json) {
    return {{Pascal}}Model(
      id: json['id'] as String,
      // TODO: map fields
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        // TODO: map fields
      };

  {{Pascal}}Model copyWith({
    String? id,
    // TODO: add fields
  }) {
    return {{Pascal}}Model(id: id ?? this.id);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is {{Pascal}}Model && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '{{Pascal}}Model(id: $id)';
}


import '../../domain/entities/{{name}}.dart';

/// Data-layer representation of [{{Pascal}}].
///
/// Serialization lives here so the entity stays free of transport concerns.
class {{Pascal}}Model extends {{Pascal}} {
  const {{Pascal}}Model({
    required super.id,
    // TODO: add fields
  });

  factory {{Pascal}}Model.fromJson(Map<String, dynamic> json) {
    return {{Pascal}}Model(
      id: json['id'] as String,
      // TODO: map fields
    );
  }

  factory {{Pascal}}Model.fromEntity({{Pascal}} entity) {
    return {{Pascal}}Model(id: entity.id);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        // TODO: map fields
      };
}

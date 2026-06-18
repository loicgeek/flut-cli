class AuthModel {
  const AuthModel({
    required this.id,
    // TODO: add fields
  });

  final String id;
  // TODO: add fields

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      id: json['id'] as String,
      // TODO: map fields
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        // TODO: map fields
      };

  AuthModel copyWith({
    String? id,
    // TODO: add fields
  }) {
    return AuthModel(id: id ?? this.id);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AuthModel(id: $id)';
}

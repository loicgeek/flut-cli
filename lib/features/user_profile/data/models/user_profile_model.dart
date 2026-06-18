class UserProfileModel {
  const UserProfileModel({
    required this.id,
    // TODO: add fields
  });

  final String id;
  // TODO: add fields

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      // TODO: map fields
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        // TODO: map fields
      };

  UserProfileModel copyWith({
    String? id,
    // TODO: add fields
  }) {
    return UserProfileModel(id: id ?? this.id);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserProfileModel(id: $id)';
}

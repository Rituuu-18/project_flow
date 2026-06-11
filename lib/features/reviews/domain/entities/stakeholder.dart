import 'package:equatable/equatable.dart';

class Stakeholder extends Equatable {
  final String id;
  final String name;
  final String role;

  const Stakeholder({
    required this.id,
    required this.name,
    required this.role,
  });

  @override
  List<Object?> get props => [id, name, role];

  Stakeholder copyWith({
    String? id,
    String? name,
    String? role,
  }) {
    return Stakeholder(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }
}

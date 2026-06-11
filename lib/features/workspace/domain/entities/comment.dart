import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String author;
  final String content;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, author, content, createdAt];
}

class Note {
  final String? id;
  final String content;
  final String? bookId;
  final String? chapterId;
  final String? userId;

  Note({
    this.id,
    required this.content,
    this.bookId,
    this.chapterId,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'bookId': bookId,
      'chapterId': chapterId,
      'userId': userId,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map, String documentId) {
    return Note(
      id: documentId,
      content: map['content'],
      bookId: map['bookId'],
      chapterId: map['chapterId'],
      userId: map['userId'],
    );
  }

  Note copyWith({
    String? id,
    String? content,
    String? bookId,
    String? chapterId,
    String? userId,
  }) {
    return Note(
      id: id ?? this.id,
      content: content ?? this.content,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      userId: userId ?? this.userId,
    );
  }
}

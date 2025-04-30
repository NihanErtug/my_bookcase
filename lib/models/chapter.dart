class Chapter {
  final String? id;
  final String bookId;
  final String name;
  final int order;
  final String chapterContent;
  final String? note;
  bool readed;
  bool isRead;
  final String? userId;
  final bool isPlaceholder;

  Chapter({
    this.id,
    required this.bookId,
    required this.name,
    required this.order,
    required this.chapterContent,
    this.note,
    this.readed = false,
    this.isRead = false,
    this.userId,
    this.isPlaceholder = false,
  });

  factory Chapter.empty(int order) {
    return Chapter(
        bookId: '',
        name: 'Bölüm $order',
        order: order,
        chapterContent: '',
        isPlaceholder: true);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'name': name,
      'order': order,
      'chapterContent': chapterContent,
      'note': note,
      'readed': readed,
      'isRead': isRead,
      'userId': userId,
      'isPlaceholder': isPlaceholder,
    };
  }

  factory Chapter.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return Chapter(
      id: documentId ?? map['id'],
      bookId: map['bookId'],
      name: map['name'],
      order: map['order'],
      chapterContent: map['chapterContent'],
      note: map['note'],
      readed: map['readed'] ?? false,
      isRead: map['isRead'] ?? false,
      userId: map['userId'],
      isPlaceholder: map['isPlaceholder'] ?? false,
    );
  }

  Chapter copyWith({
    String? id,
    String? bookId,
    String? name,
    int? order,
    String? chapterContent,
    String? note,
    bool? readed,
    bool? isRead,
    String? userId,
    bool? isPlaceholder,
  }) {
    return Chapter(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      order: order ?? this.order,
      chapterContent: chapterContent ?? this.chapterContent,
      note: note ?? this.note,
      readed: readed ?? this.readed,
      isRead: isRead ?? this.isRead,
      userId: userId ?? this.userId,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
    );
  }
}

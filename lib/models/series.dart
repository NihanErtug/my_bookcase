import 'package:bookcase/models/book.dart';
import 'package:bookcase/models/chapter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Series extends Book {
  final String seriesName;
  final int bookOrder;
  final String seriesId;
  final String type;

  Series({
    super.id,
    required super.name,
    required super.author,
    super.translator,
    super.category,
    super.publishing,
    super.publicationYear,
    super.image,
    super.localImagePath,
    super.chapters,
    super.isRead,
    super.isStarred,
    super.userId,
    super.startedDate,
    super.finishedDate,
    required this.seriesName,
    required this.bookOrder,
    required this.seriesId,
    this.type = 'series',
  });
  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = super.toMap();
    data['id'] = id;
    data['seriesName'] = seriesName;
    data['bookOrder'] = bookOrder;
    data['seriesId'] = seriesId;
    data['type'] = type;
    return data;
  }

  factory Series.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return Series(
      id: documentId,
      name: map['name'] ?? '',
      author: map['author'] ?? '',
      translator: map['translator'],
      category: map['category'],
      publishing: map['publishing'],
      publicationYear: map['publicationYear'],
      image: map['image'],
      localImagePath: map['localImagePath'],
      chapters: (map['chapters'] as List<dynamic>?)
          ?.map((e) => Chapter.fromMap(e as Map<String, dynamic>))
          .toList(),
      isRead: map['isRead'] ?? false,
      isStarred: map['isStarred'] ?? false,
      userId: map['userId'] ?? '',
      startedDate: (map['startedDate'] as Timestamp?)?.toDate(),
      finishedDate: (map['finishedDate'] as Timestamp?)?.toDate(),
      seriesName: map['seriesName'] ?? '',
      bookOrder: map['bookOrder'] ?? 0,
      seriesId: map['seriesId'] ?? '',
      type: map['type'] ?? "series",
    );
  }

  @override
  Series copyWith({
    String? id,
    String? name,
    String? author,
    String? translator,
    String? category,
    String? publishing,
    int? publicationYear,
    String? image,
    String? localImagePath,
    List<Chapter>? chapters,
    bool? isRead,
    bool? isStarred,
    String? userId,
    DateTime? startedDate,
    DateTime? finishedDate,
    String? seriesName,
    int? bookOrder,
    String? seriesId,
    String? type,
  }) {
    return Series(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      translator: translator ?? this.translator,
      category: category ?? this.category,
      publishing: publishing ?? this.publishing,
      publicationYear: publicationYear ?? this.publicationYear,
      image: image ?? this.image,
      localImagePath: localImagePath ?? this.localImagePath,
      chapters: chapters ?? this.chapters,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      userId: userId ?? this.userId,
      startedDate: startedDate ?? this.startedDate,
      finishedDate: finishedDate ?? this.finishedDate,
      seriesName: seriesName ?? this.seriesName,
      bookOrder: bookOrder ?? this.bookOrder,
      seriesId: seriesId ?? this.seriesId,
      type: type ?? this.type,
    );
  }
}

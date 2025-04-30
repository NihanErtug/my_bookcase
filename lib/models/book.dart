import 'dart:io';

import 'package:bookcase/models/chapter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String? id;
  final String name;
  final String author;
  final String? translator;
  final String? category;
  final String? publishing;
  final int? publicationYear;
  final String? image;
  final String? localImagePath;
  final List<Chapter>? chapters;
  bool isRead;
  bool isStarred;
  final String? userId;
  final DateTime? startedDate;
  final DateTime? finishedDate;

  Book({
    this.id,
    required this.name,
    required this.author,
    this.translator,
    this.category,
    this.publishing,
    this.publicationYear,
    this.image,
    this.localImagePath,
    this.chapters,
    this.isRead = false,
    this.isStarred = false,
    this.userId,
    this.startedDate,
    this.finishedDate,
  });

  File? get localImageFile =>
      localImagePath != null ? File(localImagePath!) : null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'author': author,
      'translator': translator,
      'category': category,
      'publishing': publishing,
      'publicationYear': publicationYear,
      'image': image,
      'localImagePath': localImagePath,
      'chapters': chapters?.map((e) => e.toMap()).toList(),
      'isRead': isRead,
      'isStarred': isStarred,
      'userId': userId,
      'startedDate': startedDate,
      'finishedDate': finishedDate,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return Book(
      id: documentId ?? map['id'],
      name: map['name'] ?? '',
      author: map['author'] ?? '',
      translator: map['translator'],
      category: map['category'],
      publishing: map['publishing'],
      publicationYear: map['publicationYear'],
      image: map['image'] ?? '',
      localImagePath: map['localImagePath'] ?? '',
      chapters: (map['chapters'] as List<dynamic>?)
          ?.map((e) => Chapter.fromMap(e as Map<String, dynamic>))
          .toList(),
      isRead: map['isRead'] ?? false,
      isStarred: map['isStarred'] ?? false,
      userId: map['userId'] ?? '',
      startedDate: (map['startedDate'] as Timestamp?)?.toDate(),
      finishedDate: (map['finishedDate'] as Timestamp?)?.toDate(),
    );
  }

  Book copyWith({
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
  }) {
    return Book(
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
    );
  }
}

// ignore_for_file: unused_local_variable

import 'package:bookcase/models/note.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class FirebaseServiceNotes {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  FirebaseServiceNotes(this.userId);

  Future<void> addNote(String userId, String bookId, Note note,
      {String? chapterId}) async {
    final bookDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('books')
        .doc(bookId)
        .get();
    final seriesDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('series')
        .doc(bookId)
        .get();

    final collection = seriesDoc.exists ? 'series' : 'books';

    if (chapterId != null) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .doc(bookId)
          .collection('chapters')
          .doc(chapterId)
          .collection('chapterNotes')
          .add(note.toMap());
    } else {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .doc(bookId)
          .collection('bookNotes')
          .add(note.toMap());
    }
  }

  Future<void> updateNote(String userId, String bookId, Note note,
      {String? chapterId}) async {
    final bookDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('books')
        .doc(bookId)
        .get();
    final seriesDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('series')
        .doc(bookId)
        .get();

    final collection = seriesDoc.exists ? 'series' : 'books';

    if (chapterId != null) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .doc(bookId)
          .collection('chapters')
          .doc(chapterId)
          .collection('chapterNotes')
          .doc(note.id)
          .update(note.toMap());
    } else {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .doc(bookId)
          .collection('bookNotes')
          .doc(note.id)
          .update(note.toMap());
    }
  }

  Future<void> deleteBookNote(String userId, String bookId, String noteId,
      {String? chapterId}) async {
    final bookDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('books')
        .doc(bookId)
        .get();
    final seriesDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('series')
        .doc(bookId)
        .get();

    final collection = seriesDoc.exists ? 'series' : 'books';

    if (chapterId != null) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .doc(bookId)
          .collection('chapters')
          .doc(chapterId)
          .collection('chapterNotes')
          .doc(noteId)
          .delete();
    } else {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .doc(bookId)
          .collection('bookNotes')
          .doc(noteId)
          .delete();
    }
  }

  Stream<List<Note>> getBookNotes(String userId, String bookId) {
    if (bookId.isEmpty) {
      return Stream.value([]);
    }

    return Rx.combineLatest2(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('books')
            .doc(bookId)
            .collection('bookNotes')
            .snapshots(),
        _firestore
            .collection('users')
            .doc(userId)
            .collection('series')
            .doc(bookId)
            .collection('bookNotes')
            .snapshots(),
        (QuerySnapshot bookNotesSnapshot, QuerySnapshot seriesNotesSnapshot) {
      final bookNotes = bookNotesSnapshot.docs
          .map(
              (doc) => Note.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      final seriesNotes = seriesNotesSnapshot.docs
          .map(
              (doc) => Note.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return seriesNotesSnapshot.docs.isNotEmpty ? seriesNotes : bookNotes;
    });
  }

  Stream<List<Note>> getChapterNotes(
      String userId, String bookId, String chapterId) {
    if (bookId.isEmpty || chapterId.isEmpty) {
      return Stream.value([]);
    }

    return Rx.combineLatest2(
      _firestore
          .collection('users')
          .doc(userId)
          .collection('books')
          .doc(bookId)
          .collection('chapters')
          .doc(chapterId)
          .collection('chapterNotes')
          .snapshots(),
      _firestore
          .collection('users')
          .doc(userId)
          .collection('series')
          .doc(bookId)
          .collection('chapters')
          .doc(chapterId)
          .collection('chapterNotes')
          .snapshots(),
      (QuerySnapshot bookNotesSnapshot, QuerySnapshot seriesNotesSnapshot) {
        final bookNotes = bookNotesSnapshot.docs
            .map((doc) =>
                Note.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        final seriesNotes = seriesNotesSnapshot.docs
            .map((doc) =>
                Note.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        return seriesNotesSnapshot.docs.isNotEmpty ? seriesNotes : bookNotes;
      },
    );
  }
}

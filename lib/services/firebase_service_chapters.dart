// ignore_for_file: unused_local_variable

import 'package:bookcase/models/chapter.dart';
import 'package:bookcase/providers/firebase_service_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

class FirebaseServiceChapters {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  FirebaseServiceChapters(this.userId);

  Future<void> addChapter(String bookId, Chapter chapter, WidgetRef ref) async {
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

    final chapterRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection(collection)
        .doc(bookId)
        .collection('chapters')
        .add(chapter.toMap());

    final updatedChapter = chapter.copyWith(id: chapterRef.id);
    await chapterRef.update(updatedChapter.toMap());

    // UI ın güncellenmesi için chapters provider'ı tekrar çağırıyoruz
    ref.invalidate(chapterListProvider);
  }

  Future<void> updateChapter(String bookId, Chapter chapter) async {
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

    await _firestore
        .collection('users')
        .doc(userId)
        .collection(collection)
        .doc(bookId)
        .collection('chapters')
        .doc(chapter.id)
        .update(chapter.toMap());
  }

  Future<void> deleteChapter(String bookId, String chapterId) async {
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

    final chapterRef = _firestore
        .collection('users')
        .doc(userId)
        .collection(collection)
        .doc(bookId)
        .collection('chapters')
        .doc(chapterId);

    final notesSnapshot = await chapterRef.collection('chapterNotes').get();

    for (var note in notesSnapshot.docs) {
      await note.reference.delete();
    }

    await chapterRef.delete();
  }

  Stream<List<Chapter>> getChapters(String bookId) {
    if (bookId.isEmpty) {
      return Stream.value([]);
    }

    final bookChaptersStream = _firestore
        .collection('users')
        .doc(userId)
        .collection('books')
        .doc(bookId)
        .collection('chapters')
        .orderBy('order')
        .snapshots();
    final seriesChaptersStream = _firestore
        .collection('users')
        .doc(userId)
        .collection('series')
        .doc(bookId)
        .collection('chapters')
        .orderBy('order')
        .snapshots();
    return Rx.combineLatest2(bookChaptersStream, seriesChaptersStream,
        (QuerySnapshot bookSnap, QuerySnapshot seriesSnap) {
      final bookchapters = bookSnap.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Chapter.fromMap(data, doc.id);
          })
          .where((chapter) => chapter.order != null)
          .toList();

      final seriesChapters = seriesSnap.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Chapter.fromMap(data, doc.id);
          })
          .where((chapter) => chapter.order != null)
          .toList();

      final chapters =
          seriesSnap.docs.isNotEmpty ? seriesChapters : bookchapters;

      // eksik bölümleri doldurma
      if (chapters.isNotEmpty) {
        final maxOrder =
            chapters.map((c) => c.order).reduce((a, b) => a > b ? a : b);
        final List<Chapter> completeChapters = [];

        for (int i = 1; i <= maxOrder; i++) {
          final existingChapter = chapters.firstWhere(
              (chapter) => chapter.order == i,
              orElse: () => Chapter.empty(i));
          completeChapters.add(existingChapter);
        }
        return completeChapters;
      }

      return chapters;
    });
  }

  Future<void> updateChapterReadStatus(
      String bookId, String chapterId, bool newStatus, bool isRead) async {
    final seriesDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('series')
        .doc(bookId)
        .get();

    final collection = seriesDoc.exists ? 'series' : 'books';

    await _firestore
        .collection('users')
        .doc(userId)
        .collection(collection)
        .doc(bookId)
        .collection('chapters')
        .doc(chapterId)
        .update({'readed': newStatus, 'isRead': isRead});
  }
}

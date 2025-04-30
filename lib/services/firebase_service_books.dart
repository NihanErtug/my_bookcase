import 'package:bookcase/models/book.dart';
import 'package:bookcase/models/chapter.dart';
import 'package:bookcase/models/series.dart';

import 'package:bookcase/services/firebase_service_chapters.dart';

import 'package:bookcase/services/firebase_service_notes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:rxdart/rxdart.dart';

class FirebaseServices {
  final String userId;
  final FirebaseServiceBooks booksService;
  final FirebaseServiceNotes notesService;
  final FirebaseServiceChapters chaptersService;

  FirebaseServices(this.userId)
      : booksService = FirebaseServiceBooks(userId),
        notesService = FirebaseServiceNotes(userId),
        chaptersService = FirebaseServiceChapters(userId);
}

class FirebaseServiceBooks {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  FirebaseServiceBooks(this.userId);

  CollectionReference get _booksCollection =>
      _firestore.collection('users').doc(userId).collection('books');

  CollectionReference get _seriesCollection =>
      _firestore.collection('users').doc(userId).collection('series');

  Future<void> addBook(Book book) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    if (book is Series) {
      final docRef = _seriesCollection.doc();

      final bookWithId = book.copyWith(id: docRef.id, userId: currentUserId);

      await docRef.set(bookWithId.toMap());
    } else {
      final docRef = await _booksCollection.add(book.toMap());

      final updatedBook = book.copyWith(id: docRef.id, userId: currentUserId);

      await docRef.update(updatedBook.toMap());
    }
  }

  Future<void> deleteBook(String bookId) async {
    final bookDoc = await _booksCollection.doc(bookId).get();
    final seriesDoc = await _seriesCollection.doc(bookId).get();

    if (seriesDoc.exists) {
      await _deleteSubCollections(_seriesCollection, bookId);
      await _seriesCollection.doc(bookId).delete();
    } else if (bookDoc.exists) {
      await _deleteSubCollections(_booksCollection, bookId);
      await _booksCollection.doc(bookId).delete();
    }
  }

  Future<void> _deleteSubCollections(
      CollectionReference parentCollection, String bookId) async {
    final chaptersSnapshot =
        await parentCollection.doc(bookId).collection('chapters').get();

    for (var chapter in chaptersSnapshot.docs) {
      final chapterNotesSnapshot = await parentCollection
          .doc(bookId)
          .collection('chapters')
          .doc(chapter.id)
          .collection('chapterNotes')
          .get();

      for (var note in chapterNotesSnapshot.docs) {
        await note.reference.delete();
      }
      await chapter.reference.delete();
    }

    final notesSnapshot =
        await parentCollection.doc(bookId).collection('bookNotes').get();

    for (var note in notesSnapshot.docs) {
      await note.reference.delete();
    }
  }

  Future<void> deleteSeriesBooks(String seriesId) async {
    try {
      final seriesBooksQuery =
          await _seriesCollection.where('seriesId', isEqualTo: seriesId).get();

      if (seriesBooksQuery.docs.isEmpty) {
        throw Exception("Seriye ait kitap bulunamadı: $seriesId");
      }

      for (var doc in seriesBooksQuery.docs) {
        await _deleteSubCollections(_seriesCollection, doc.id);
        await doc.reference.delete();
      }
      print('Seriye ait tüm kitaplar başarıyla silindi: $seriesId');
    } catch (e) {
      print("Seri kitaplarını silme hatası: $e");
      rethrow;
    }
  }

  Future<void> deleteSeries(String seriesId) async {
    try {
      await deleteSeriesBooks(seriesId);

      await _seriesCollection.doc(seriesId).delete();

      print("Seri ve tüm kitapları başarıyla silindi: $seriesId");
    } catch (e) {
      print("Seri silme hatası: $e");
      rethrow;
    }
  }

  Stream<List<Book>> getBooks() {
    return Rx.combineLatest2(
      _booksCollection.snapshots(),
      _seriesCollection.snapshots(),
      (QuerySnapshot booksSnapshot, QuerySnapshot seriesSnapshot) async* {
        final regularBooks = await Future.wait(
          booksSnapshot.docs.map((doc) async {
            final chaptersSnapshot = await _booksCollection
                .doc(doc.id)
                .collection('chapters')
                .orderBy('order')
                .get();

            // Bölümleri Chapter nesnelerine dönüştür
            final chapters = chaptersSnapshot.docs
                .map((chapterDoc) =>
                    Chapter.fromMap(chapterDoc.data(), chapterDoc.id))
                .toList();

            // Book nesnesini oluştur ve bölümleri ekle
            return Book.fromMap(doc.data() as Map<String, dynamic>, doc.id)
                .copyWith(chapters: chapters);
          }),
        );

        final seriesBooks = await Future.wait(
          seriesSnapshot.docs.map((doc) async {
            final chaptersSnapshot = await _seriesCollection
                .doc(doc.id)
                .collection('chapters')
                .orderBy('order')
                .get();

            // Bölümleri Chapter nesnelerine dönüştür
            final chapters = chaptersSnapshot.docs
                .map((chapterDoc) =>
                    Chapter.fromMap(chapterDoc.data(), chapterDoc.id))
                .toList();

            // Series nesnesini oluştur ve bölümleri ekle
            return Series.fromMap(doc.data() as Map<String, dynamic>, doc.id)
                .copyWith(chapters: chapters);
          }),
        );

        yield [...regularBooks, ...seriesBooks];
      },
    ).asyncExpand((event) => event);
  }

  Stream<Book?> getBookById(String bookId) {
    return Stream.fromFuture(Future.wait([
      _booksCollection.doc(bookId).get(),
      _seriesCollection.doc(bookId).get(),
    ])).map((snapshots) {
      final bookDoc = snapshots[0];
      final seriesDoc = snapshots[1];

      if (seriesDoc.exists) {
        return Series.fromMap(
            seriesDoc.data() as Map<String, dynamic>, seriesDoc.id);
      } else if (bookDoc.exists) {
        return Book.fromMap(bookDoc.data() as Map<String, dynamic>, bookDoc.id);
      }
      return null;
    });
  }

  Future<void> updateBookStatus(String bookId,
      {bool? isRead, bool? isStarred}) async {
    final bookDoc = await _booksCollection.doc(bookId).get();
    final seriesDoc = await _seriesCollection.doc(bookId).get();

    final Map<String, dynamic> updates = {};
    if (isRead != null) updates['isRead'] = isRead;
    if (isStarred != null) updates['isStarred'] = isStarred;

    if (seriesDoc.exists) {
      await _seriesCollection.doc(bookId).update(updates);
    } else if (bookDoc.exists) {
      await _booksCollection.doc(bookId).update(updates);
    }
  }

  Future<void> updateSeriesInfo(
      String seriesId, String newSeriesName, String newAuthorName) async {
    try {
      final seriesQuery =
          await _seriesCollection.where('seriesId', isEqualTo: seriesId).get();

      if (seriesQuery.docs.isEmpty) {
        throw Exception('Belge bulunamadı: $seriesId');
      }
      for (var doc in seriesQuery.docs) {
        await doc.reference
            .update({'seriesName': newSeriesName, 'author': newAuthorName});
      }
    } catch (e) {
      print("Güncelleme hatası: $e");
      rethrow;
    }
  }

  Stream<List<Series>> getSeriesBooks(String seriesId) {
    return _seriesCollection
        .where('seriesId', isEqualTo: seriesId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Series.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}

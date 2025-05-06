import 'package:bookcase/models/book.dart';
import 'package:bookcase/models/chapter.dart';
import 'package:bookcase/models/note.dart';
import 'package:bookcase/models/series.dart';
import 'package:bookcase/providers/theme_notifier.dart';
import 'package:bookcase/services/auth_service.dart';
import 'package:bookcase/services/firebase_service_books.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseServicesProvider = Provider<FirebaseServices>((ref) {
  final user = ref.watch(authStateProvider).value;

  if (user == null) throw Exception('Kullanıcı oturum açmamış.');

  return FirebaseServices(user.uid);
});

final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);

final seriesListProvider =
    StreamProvider.family<List<Series>, String>((ref, userId) {
  final firebaseService = ref.watch(firebaseServicesProvider);
  return firebaseService.booksService.getSeriesBooks(userId);
});

final bookListProvider =
    StreamProvider.family<List<Book>, String>((ref, userId) {
  final firebaseService = ref.watch(firebaseServicesProvider);

  return firebaseService.booksService.getBooks().map((books) {
    final List<Book> regularBooks = [];
    final List<Series> seriesBooks = [];

    for (var book in books) {
      if (book is Series) {
        if (book.seriesId.isNotEmpty) {
          seriesBooks.add(book);
        } else {
          regularBooks.add(book);
        }
      } else {
        regularBooks.add(book);
      }
    }

    // Seri kitaplarını seriesId ve bookOrder'a göre sırala
    seriesBooks.sort((a, b) {
      final seriesCompare = a.seriesId.compareTo(b.seriesId);
      if (seriesCompare != 0) return seriesCompare;
      return a.bookOrder.compareTo(b.bookOrder);
    });

    final seriesGroups = groupBy(seriesBooks, (Series s) => s.seriesId);

    final result = [...regularBooks, ...seriesBooks];

    return result;
  });
});

final bookDetailProvider = StreamProvider.autoDispose
    .family<Book?, (String bookId, String userId)>((ref, args) {
  final bookId = args.$1;
  final userId = args.$2;

  if (bookId.isEmpty) {
    return Stream.value(null);
  }
  final firebaseService = ref.watch(firebaseServicesProvider);
  return firebaseService.booksService.getBookById(bookId);
});

final bookIdProvider =
    StateProvider<String>((ref) => ''); //seçilen kitap için Id sağlayıcı

final chapterListProvider = StreamProvider<List<Chapter>>((ref) {
  final bookId = ref.watch(bookIdProvider);
  final firebaseService = ref.watch(firebaseServicesProvider);

  return bookId.isEmpty
      ? Stream.value([])
      : firebaseService.chaptersService.getChapters(bookId);
});

final getBookNotesProvider = StreamProvider<List<Note>>((ref) {
  final bookId = ref.watch(bookIdProvider);
  if (bookId.isEmpty) {
    return Stream.value([]);
  }
  final firebaseService = ref.watch(firebaseServicesProvider);
  final userId = firebaseService.userId;

  return firebaseService.notesService.getBookNotes(userId, bookId);
});

final getChapterNotesProvider = StreamProvider<List<Note>>((ref) {
  final bookId = ref.watch(bookIdProvider);
  final chapterId = ref.watch(chapterIdProvider);

  if (bookId.isEmpty || chapterId.isEmpty) {
    return Stream.value([]);
  }
  final firebaseService = ref.watch(firebaseServicesProvider);
  final userId = firebaseService.userId;
  return firebaseService.notesService
      .getChapterNotes(userId, bookId, chapterId);
});

final chapterIdProvider = StateProvider<String>((ref) => '');
// seçilen bölüm için Id sağlayıcı

final fontSettingsProvider =
    StateNotifierProvider<FontSettingsNotifier, FontSettings>(
        (ref) => FontSettingsNotifier());

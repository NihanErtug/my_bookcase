import 'package:bookcase/models/book.dart';
import 'package:bookcase/models/series.dart';
import 'package:bookcase/providers/firebase_service_provider.dart';
import 'package:bookcase/providers/search_filter_notifier.dart';

import 'package:bookcase/screens/add_book.dart';
import 'package:bookcase/screens/book_detail_page.dart';
import 'package:bookcase/screens/home_page.dart';

import 'package:bookcase/utils/build_trailing_icons.dart';
import 'package:bookcase/utils/draggable_fab.dart';

import 'package:bookcase/utils/turkishSort.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookListPage extends ConsumerStatefulWidget {
  const BookListPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BookListPageState();
}

class _BookListPageState extends ConsumerState<BookListPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _letterPositions = {};

  @override
  Widget build(BuildContext context) {
    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Giriş yapılmamış')),
      );
    }

    final bookList = ref.watch(bookListProvider(userId));

    return Scaffold(
      appBar: AppBar(
        //automaticallyImplyLeading: false,
        title: Text('Kitap Listesi'),
        actions: [
          IconButton(
              onPressed: () {
                //Navigator.pop(context, true);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => HomePage()));
                ref.read(searchFilterProvider.notifier).resetFilters();
              },
              icon: Icon(Icons.home)),
        ],
      ),
      body: bookList.when(
        data: (books) {
          final normalBooks = books.where((book) => book is! Series).toList();

          return Stack(
            children: [
              _buildBookList(context, books),
              if (normalBooks.isNotEmpty) _buildAlphabetBar(),
              if (normalBooks.isEmpty)
                Center(child: Text("Henüz Kitap Eklenmemiş.")),
            ],
          );
        },
        error: (error, stackTrace) {
          return Center(child: Text("Hata oluştu: ${error.toString()}"));
        },
        loading: () {
          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: DraggableFAB(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => AddBookScreen()));
          },
          icon: Icon(Icons.book)),
    );
  }

  Widget _buildBookList(BuildContext context, List<Book> books) {
    final List<Book> standaloneBooks = [];

    for (var book in books) {
      if (book is! Series) {
        standaloneBooks.add(book);
      }
    }

    standaloneBooks.sort((a, b) => turkishSort(a.name, b.name));
    _calculateLetterPositions(standaloneBooks);

    return ListView(
      controller: _scrollController,
      children: [
        ...standaloneBooks.map((book) => Container(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: GestureDetector(
                onTap: () {
                  ref.read(bookIdProvider.notifier).state = book.id!;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              BookDetailPage(bookId: book.id!)));
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.15,
                      height: MediaQuery.of(context).size.width * 0.2,
                      child: buildImage(book.image, context),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            book.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text('Yazar: ${book.author}',
                              style: Theme.of(context).textTheme.bodyMedium),
                          Text('Bölüm Sayısı: ${book.chapters?.length ?? 0}',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    buildTrailingIcons(context, ref, book),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  void _calculateLetterPositions(List<Book> books) {
    _letterPositions.clear();
    double position = 0.0;
    String? lastLetter;

    for (var book in books) {
      final letter = book.name[0].toUpperCase();
      if (letter != lastLetter) {
        _letterPositions[letter] = position;
        lastLetter = letter;
      }
      position += 80.0;
    }
  }

  Widget _buildAlphabetBar() {
    final letters = _letterPositions.keys.toList();
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: letters.map((letter) {
          return GestureDetector(
            onTap: () {
              if (_letterPositions.containsKey(letter)) {
                _scrollController.animateTo(
                  _letterPositions[letter]!,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                letter,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

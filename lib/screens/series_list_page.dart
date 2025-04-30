import 'package:bookcase/models/book.dart';
import 'package:bookcase/models/series.dart';
import 'package:bookcase/providers/firebase_service_provider.dart';
import 'package:bookcase/screens/add_book.dart';
import 'package:bookcase/screens/book_detail_page.dart';
import 'package:bookcase/screens/book_list_page.dart';
import 'package:bookcase/screens/home_page.dart';

import 'package:bookcase/utils/build_trailing_icons.dart';
import 'package:bookcase/utils/draggable_fab.dart';
import 'package:bookcase/utils/series_dialog.dart';
import 'package:bookcase/utils/turkishSort.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SeriesListPage extends ConsumerStatefulWidget {
  const SeriesListPage({super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SeriesListPageState();
}

class _SeriesListPageState extends ConsumerState<SeriesListPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _letterPositions = {};

  @override
  Widget build(BuildContext context) {
    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
    final bookList = ref.watch(bookListProvider(userId!));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Seri Kitaplar"),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomePage()));
              },
              icon: Icon(Icons.home))
        ],
      ),
      body: bookList.when(data: (books) {
        final seriesGroupsBooks = _groupSeriesBooks(books);

        return Stack(
          children: [
            _buildSeriesBookList(context, books, ref),
            if (seriesGroupsBooks.isNotEmpty) _buildAlphabetBar(),
            if (seriesGroupsBooks.isEmpty)
              Center(
                  child: Text(
                "Henüz Seri Kitap Eklenmemiş.",
                style: TextStyle(fontSize: 16),
              )),
          ],
        );
      }, error: (e, stackTrace) {
        return Center(
          child: Text("Hata oluştu: $e"),
        );
      }, loading: () {
        return Center(child: CircularProgressIndicator());
      }),
      floatingActionButton: DraggableFAB(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => AddBookScreen()));
          },
          icon: Icon(Icons.book)),
    );
  }

  Widget _buildSeriesBookList(
      BuildContext context, List<Book> books, WidgetRef ref) {
    final Map<String, List<Series>> seriesGroups = {};

    for (var book in books) {
      if (book is Series) {
        if (!seriesGroups.containsKey(book.seriesId)) {
          seriesGroups[book.seriesId] = [];
        }
        seriesGroups[book.seriesId]!.add(book);
      }
    }

    final sortedSeriesGroups = seriesGroups.entries.toList()
      ..sort((a, b) => turkishSort(a.value.first.seriesName.toLowerCase(),
          b.value.first.seriesName.toLowerCase()));

    final allSeriesBooks =
        sortedSeriesGroups.expand((entry) => entry.value).toList();

    _calculateLetterPositions(allSeriesBooks);

    return ListView(
      controller: _scrollController,
      children: [
        ...sortedSeriesGroups.map((entry) {
          final seriesId = entry.key;

          return _buildSeriesCard(context, ref, seriesId);
        })
      ],
    );
  }

  Widget _buildSeriesCard(
      BuildContext context, WidgetRef ref, String seriesId) {
    final firebaseService = ref.read(firebaseServicesProvider);

    return StreamBuilder<List<Series>>(
        stream: firebaseService.booksService.getSeriesBooks(seriesId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return SizedBox.shrink();
          }

          final seriesBooks = snapshot.data!
            ..sort((a, b) => a.bookOrder.compareTo(b.bookOrder));
          final firstBook = seriesBooks.first;

          return Card(
            margin: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: GestureDetector(
                    onTap: () {
                      _editSeriesInfo(context, ref, seriesId,
                          firstBook.seriesName, firstBook.author);
                    },
                    child: Text(
                      '${firstBook.seriesName} (${seriesBooks.length} Kitap)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.deepPurple),
                    ),
                  ),
                  subtitle: Text(
                    'Yazar: ${firstBook.author}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Wrap(
                  spacing: 10, // yatay boşluk
                  runSpacing: 8, // dikey b.
                  alignment: WrapAlignment.start,
                  children: seriesBooks.map((book) {
                    return GestureDetector(
                      onTap: () {
                        ref.read(bookIdProvider.notifier).state = book.id!;
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    BookDetailPage(bookId: book.id!)));
                      },
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 18,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Kitap ${book.bookOrder}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.blueGrey),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.15,
                              height: MediaQuery.of(context).size.width * 0.2,
                              child: buildImage(book.image, context),
                            ),
                            SizedBox(height: 8),
                            Text(
                              book.name,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        });
  }

  void _editSeriesInfo(BuildContext context, WidgetRef ref, String seriesId,
      String currentSeriesName, String currentAuthorName) {
    final seriesNameController = TextEditingController(text: currentSeriesName);
    final seriesAuthorController =
        TextEditingController(text: currentAuthorName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Seriyi Düzenle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: seriesNameController,
              decoration: InputDecoration(labelText: 'Yeni Seri Adı'),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: seriesAuthorController,
              decoration: InputDecoration(labelText: 'Yeni Yazar Adı'),
            ),
          ],
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("İptal")),
                  TextButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(firebaseServicesProvider)
                            .booksService
                            .updateSeriesInfo(
                                seriesId,
                                seriesNameController.text,
                                seriesAuthorController.text);

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Seri bilgileri başarıyla güncellendi!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Güncelleme hatası: $e')),
                        );
                      }
                    },
                    child: Text("Kaydet"),
                  ),
                ],
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                      context: context,
                      builder: (context) => SeriesDialog(
                            onSeriesSelected: (seriesId) {},
                            preSelectedSeriesId: seriesId,
                          ));
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Seriye Yeni Kitap Ekle",
                    style: TextStyle(
                        color: Colors.deepPurpleAccent,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: Text(
                                  "Seriyi silmek istediğinizden emin misiniz?"),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("İptal")),
                                TextButton(
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(firebaseServicesProvider)
                                            .booksService
                                            .deleteSeries(seriesId);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content:
                                                    Text("Seri silindi.")));
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    "Seri silinemedi: $e")));
                                      }
                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  BookListPage()));
                                    },
                                    child: Text("Sil")),
                              ],
                            ));
                  },
                  style: ElevatedButton.styleFrom(
                      side: BorderSide(color: Colors.grey, width: 2.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.dangerous, color: Colors.red, size: 30),
                      SizedBox(width: 8),
                      Text("Seriyi Sil"),
                    ],
                  )),
            ],
          )
        ],
      ),
    );
  }

  Map<String, List<Series>> _groupSeriesBooks(List<Book> books) {
    final Map<String, List<Series>> seriesGroups = {};
    for (var book in books) {
      if (book is Series) {
        if (!seriesGroups.containsKey(book.seriesId)) {
          seriesGroups[book.seriesId] = [];
        }
        seriesGroups[book.seriesId]!.add(book);
      }
    }
    return seriesGroups;
  }

  void _calculateLetterPositions(List<Series> seriesList) {
    _letterPositions.clear();
    double position = 0.0;
    String? lastLetter;

    for (var series in seriesList) {
      final letter = series.seriesName[0].toUpperCase();
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
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Text(
                letter,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

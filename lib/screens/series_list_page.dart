import 'package:bookcase/models/series.dart';
import 'package:bookcase/providers/firebase_service_provider.dart';
import 'package:bookcase/screens/add_book.dart';
import 'package:bookcase/screens/book_detail_page.dart';
import 'package:bookcase/screens/book_list_page.dart';
import 'package:bookcase/screens/home_page.dart';

import 'package:bookcase/utils/build_trailing_icons_image.dart';
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
  final Map<String, GlobalKey> _letterKeys = {};

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseAuthProvider).currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final seriesList = ref.watch(seriesListProvider(user.uid));

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
      body: seriesList.when(data: (seriesBooks) {
        if (seriesBooks.isEmpty) {
          return Center(
              child: Text(
            "Henüz Seri Kitap Eklenmemiş.",
            style: TextStyle(fontSize: 16),
          ));
        }

        final Map<String, List<Series>> seriesGroups = {};
        for (var book in seriesBooks) {
          seriesGroups.putIfAbsent(book.seriesId, () => []).add(book);
        }

        final sortedSeriesGroups = seriesGroups.entries.toList()
          ..sort((a, b) => turkishSort(a.value.first.seriesName.toLowerCase(),
              b.value.first.seriesName.toLowerCase()));

        _letterKeys.clear();
        for (var entry in sortedSeriesGroups) {
          final firstLetter = entry.value.first.seriesName[0].toUpperCase();
          if (!_letterKeys.containsKey(firstLetter)) {
            _letterKeys[firstLetter] = GlobalKey();
          }
        }

        return Stack(
          children: [
            ListView(
              controller: _scrollController,
              children: sortedSeriesGroups.map((entry) {
                final firstLetter =
                    entry.value.first.seriesName[0].toUpperCase();
                return Container(
                  key: _letterKeys[firstLetter],
                  child:
                      _buildSeriesCardFromLocalData(context, ref, entry.value),
                );
              }).toList(),
            ),
            if (sortedSeriesGroups.isNotEmpty) _buildAlphabetBar(),
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

  Widget _buildSeriesCardFromLocalData(
      BuildContext context, WidgetRef ref, List<Series> seriesBooks) {
    if (seriesBooks.isEmpty) return SizedBox.shrink();

    seriesBooks.sort((a, b) => a.bookOrder.compareTo(b.bookOrder));

    final firstBook = seriesBooks.first;
    final seriesId = firstBook.seriesId;

    return Card(
      margin: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: GestureDetector(
              onTap: () {
                _editSeriesInfo(context, ref, seriesId, firstBook.seriesName,
                    firstBook.author);
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
            spacing: 10,
            runSpacing: 8,
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
                      Text(book.name,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center),
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

  Widget _buildAlphabetBar() {
    final letters = _letterKeys.keys.toList()..sort();

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: letters.map((letter) {
            return GestureDetector(
              onTap: () {
                final key = _letterKeys[letter];
                if (key?.currentContext != null) {
                  Scrollable.ensureVisible(key!.currentContext!,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
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
      ),
    );
  }
}

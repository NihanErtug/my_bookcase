import 'package:bookcase/models/book.dart';
import 'package:bookcase/models/series.dart';

import 'package:bookcase/screens/series_list_page.dart';
import 'package:bookcase/services/firebase_service_books.dart';
import 'package:bookcase/utils/custom_text_form_field.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SeriesDialog extends StatefulWidget {
  final Function(String?) onSeriesSelected;
  final String? initialSeriesId;
  final String? preSelectedSeriesId;

  const SeriesDialog(
      {super.key,
      required this.onSeriesSelected,
      this.initialSeriesId,
      this.preSelectedSeriesId});

  @override
  State<SeriesDialog> createState() => _SeriesDialogState();
}

class _SeriesDialogState extends State<SeriesDialog> {
  bool isNewSeries = true;
  final seriesNameController = TextEditingController();
  final authorController = TextEditingController();
  List<TextEditingController> bookControllers = [TextEditingController()];
  String? selectedSeriesId;
  final _formKey = GlobalKey<FormState>();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedSeriesId != null) {
      isNewSeries = false;
      selectedSeriesId = widget.preSelectedSeriesId;

      _loadSeriesInfo(widget.preSelectedSeriesId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Seriye Kitap Ekle"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.preSelectedSeriesId == null)
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text('Yeni Seri')),
                    ButtonSegment(
                        value: false, label: Text('Mevcut Seriye Ekle')),
                  ],
                  selected: {isNewSeries},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      isNewSeries = newSelection.first;
                    });
                  },
                ),
              SizedBox(height: 16),
              if (isNewSeries)
                _buildNewSeriesForm()
              else
                _buildExistingSeriesForm(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text("İptal")),
        TextButton(onPressed: _saveSeries, child: Text("Kaydet")),
      ],
    );
  }

  Widget _buildNewSeriesForm() {
    return Column(
      children: [
        CustomTextFormField(
            controller: seriesNameController,
            labelText: 'Seri Adı',
            validatorMessage: 'Seri adı boş olamaz'),
        CustomTextFormField(
            controller: authorController,
            labelText: 'Yazar',
            validatorMessage: 'Yazar adı boş olamaz'),
        ...bookControllers.asMap().entries.map((entry) {
          return Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                    controller: entry.value,
                    labelText: 'Kitap ${entry.key + 1}',
                    validatorMessage: 'Kitap adı boş olamaz'),
              ),
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () => _removeBookField(entry.key),
              ),
            ],
          );
        }).toList(),
        SizedBox(height: 8),
        ElevatedButton(onPressed: _addBookField, child: Text("Kitap Ekle")),
      ],
    );
  }

  Widget _buildExistingSeriesForm() {
    return StreamBuilder<List<Book>>(
        stream: FirebaseServiceBooks(userId).getBooks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Hata oluştu: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          final seriesList = snapshot.data!
              .whereType<Series>()
              .where((series) => series.seriesId.isNotEmpty)
              .toList();

          if (seriesList.isEmpty) {
            return Center(child: Text('Henüz hiç seri eklenmemiş.'));
          }
          final groupedSeries = groupSeriesBySeriesId(seriesList);

          if (widget.preSelectedSeriesId != null) {
            selectedSeriesId = widget.preSelectedSeriesId;
          }

          return Column(
            children: [
              DropdownButtonFormField(
                isExpanded: true,
                value: selectedSeriesId,
                items: groupedSeries.entries.map((entry) {
                  final firstBook = entry.value.first;
                  return DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                          '${firstBook.seriesName} (${entry.value.length} kitap)'));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSeriesId = value;
                    if (value != null && groupedSeries.containsKey(value)) {
                      final firstBook = groupedSeries[value]!.first;
                      authorController.text = firstBook.author;
                      seriesNameController.text = firstBook.seriesName;
                    }
                  });
                },
                decoration: InputDecoration(labelText: 'Seri Seçin'),
              ),
              if (selectedSeriesId != null) ...[
                SizedBox(height: 16),
                StreamBuilder<List<Book>>(
                    stream: FirebaseServiceBooks(userId).getBooks(),
                    builder: (context, seriesSnapshot) {
                      if (seriesSnapshot.hasError) {
                        return Text('Hata oluştu: ${seriesSnapshot.error}');
                      }
                      if (!seriesSnapshot.hasData) {
                        return CircularProgressIndicator();
                      }
                      final seriesBooks = seriesSnapshot.data!
                          .whereType<Series>()
                          .where(
                              (series) => series.seriesId == selectedSeriesId)
                          .toList()
                        ..sort((a, b) => a.bookOrder.compareTo(b.bookOrder));

                      // Mevcut kitapların sırasını kontrol et
                      final existingOrders =
                          seriesBooks.map((book) => book.bookOrder).toList();
                      int nextOrder = 1;
                      while (existingOrders.contains(nextOrder)) {
                        nextOrder++;
                      }

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blueGrey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mevcut Kitaplar:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                ...seriesBooks.map((book) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Text(
                                          '${book.bookOrder}. ${book.name}'),
                                    )),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('Yeni Eklenecek Kitaplar:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          ...bookControllers.asMap().entries.map((entry) {
                            return _buildBookField(
                                entry.key, seriesBooks.length + entry.key + 1);
                          }).toList(),
                          SizedBox(height: 16),
                          ElevatedButton(
                              onPressed: _addBookField,
                              child: Text("Yeni Kitap Ekle")),
                          SizedBox(height: 16),
                        ],
                      );
                    }),
              ]
            ],
          );
        });
  }

  Map<String, List<Series>> groupSeriesBySeriesId(List<Series> series) {
    return groupBy(series, (Series s) => s.seriesId);
  }

  Widget _buildBookField(int index, int startingOrder) {
    return Row(
      children: [
        Expanded(
            child: TextFormField(
          controller: bookControllers[index],
          decoration: InputDecoration(labelText: 'Kitap Adı'),
        )),
        SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: TextFormField(
            controller: bookOrderControllers[index],
            decoration: InputDecoration(labelText: 'Sıra'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              if (value.isNotEmpty) {
                int? order = int.tryParse(value);
                if (order != null && order > 0) {
                  bookOrderControllers[index].text = order.toString();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Lütfen geçerli bir sıra numarası girin (1, 2, 3, ...)')));

                  // geçersiz değeri temizliyoruz
                  bookOrderControllers[index].text = '';
                }
              } else {
                // girdi boşsa sıra numarasını temizliyoruz
                bookOrderControllers[index].text = '';
              }
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: () => _removeBookField(index),
        ),
      ],
    );
  }

  List<TextEditingController> bookOrderControllers = [TextEditingController()];

  void _addBookField() {
    setState(() {
      bookControllers.add(TextEditingController());
      bookOrderControllers.add(TextEditingController());
    });
  }

  void _removeBookField(int index) {
    if (bookControllers.length > 1) {
      setState(() {
        bookControllers[index].dispose();
        bookControllers.removeAt(index);
        bookOrderControllers[index].dispose();
        bookOrderControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveSeries() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lütfen bu alanları doldurun")));
      return;
    }

    // Yazar adı ve seri adı boşsa uyarı ver
    if (authorController.text.trim().isEmpty ||
        seriesNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Yazar adı ve seri adı boş olamaz")),
      );
      return;
    }

    try {
      if (isNewSeries) {
        final seriesId = DateTime.now().microsecondsSinceEpoch.toString();

        final nonEmtyBooks = bookControllers
            .where((controller) => controller.text.trim().isNotEmpty)
            .toList();

        for (var i = 0; i < nonEmtyBooks.length; i++) {
          final series = Series(
            name: nonEmtyBooks[i].text.trim(),
            author: authorController.text.trim(),
            seriesName: seriesNameController.text.trim(),
            bookOrder: i + 1,
            seriesId: seriesId,
          );
          await FirebaseServiceBooks(userId).addBook(series);
        }
      } else if (selectedSeriesId != null) {
        final existingBooks = await FirebaseServiceBooks(userId)
            .getBooks()
            .map((books) => books
                .whereType<Series>()
                .where((series) => series.seriesId == selectedSeriesId)
                .toList())
            .first;

        final existingOrders =
            existingBooks.map((book) => book.bookOrder).toList();

        final nonEmtyBooks = bookControllers
            .where((controller) => controller.text.trim().isNotEmpty)
            .toList();

        for (var i = 0; i < nonEmtyBooks.length; i++) {
          int bookOrder; // varsayılan sıra numarası  = i + 1

          // kullanıcının girdiği sıra numarasını alıyoruz
          if (bookOrderControllers[i].text.isNotEmpty) {
            bookOrder = int.parse(bookOrderControllers[i].text);

            // sıra numarası zaten varsa uyarı veriyoruz
            if (existingOrders.contains(bookOrder)) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Sıra numarası $bookOrder zaten kullanılıyor. Lütfen farklı bir sıra numarası girin.')));
              return;
            }
          } else {
            bookOrder = getNextAvailableOrder(existingOrders);
            existingOrders.add(bookOrder);
          }

          final series = Series(
              name: nonEmtyBooks[i].text.trim(),
              author: authorController.text.trim(),
              seriesName: seriesNameController.text.trim(),
              //bookOrder: nextOrder + i,
              bookOrder: bookOrder,
              seriesId: selectedSeriesId!);
          await FirebaseServiceBooks(userId).addBook(series);
        }
        widget.onSeriesSelected(selectedSeriesId);
      }

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => SeriesListPage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
  }

  int getNextAvailableOrder(List<int> existingOrders) {
    int nextOrder = 1;
    while (existingOrders.contains(nextOrder)) {
      nextOrder++;
    }
    return nextOrder;
  }

  @override
  void dispose() {
    seriesNameController.dispose();
    authorController.dispose();
    for (var controller in bookControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSeriesInfo(String seriesId) async {
    final seriesBooks = await FirebaseServiceBooks(userId)
        .getBooks()
        .map((books) => books
            .whereType<Series>()
            .where((series) => series.seriesId == seriesId)
            .toList())
        .first;

    if (seriesBooks.isNotEmpty) {
      final firstBook = seriesBooks.first;
      setState(() {
        authorController.text = firstBook.author;
        seriesNameController.text = firstBook.seriesName;
      });
    }
  }
}

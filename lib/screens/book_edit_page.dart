import 'package:bookcase/models/book.dart';
import 'package:bookcase/models/series.dart';
import 'package:bookcase/providers/firebase_service_provider.dart';
import 'package:bookcase/services/firebase_service_books.dart';
import 'package:bookcase/utils/book_date_picker.dart';
import 'package:bookcase/utils/image_section.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BookEditPage extends ConsumerStatefulWidget {
  final Book book;

  const BookEditPage({required this.book, super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BookEditPageState();
}

class _BookEditPageState extends ConsumerState<BookEditPage> {
  late TextEditingController nameController;
  late TextEditingController authorController;
  late TextEditingController translatorController;
  late TextEditingController categoryController;
  late TextEditingController publishingController;
  late TextEditingController publicationYearController;
  late TextEditingController imageController;
  late TextEditingController seriesNameController;
  late TextEditingController bookOrderController;
  late bool isSeriesBook = widget.book is Series;
  DateTime? startedDateController;
  DateTime? finishedDateController;
  bool isStartedDateCleared = false;
  bool isFinishedDateCleared = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.book.name);
    authorController = TextEditingController(text: widget.book.author);
    translatorController = TextEditingController(text: widget.book.translator);
    categoryController = TextEditingController(text: widget.book.category);
    publishingController = TextEditingController(text: widget.book.publishing);
    publicationYearController = TextEditingController(
        text: widget.book.publicationYear?.toString() ?? '');
    imageController = TextEditingController(text: widget.book.image);
    seriesNameController = TextEditingController(
        text: widget.book is Series ? (widget.book as Series).seriesName : '');
    bookOrderController = TextEditingController(
        text: widget.book is Series
            ? (widget.book as Series).bookOrder.toString()
            : '');
    startedDateController = widget.book.startedDate;
    finishedDateController = widget.book.finishedDate;
  }

  @override
  void dispose() {
    nameController.dispose();
    authorController.dispose();
    translatorController.dispose();
    categoryController.dispose();
    publishingController.dispose();
    publicationYearController.dispose();
    imageController.dispose();
    seriesNameController.dispose();
    bookOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = ref.read(firebaseServicesProvider).booksService;

    return Scaffold(
      appBar: AppBar(
        title: Text("Kitap Düzenle"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
                title: Text('Bu kitap bir serinin parçası mı?'),
                value: isSeriesBook,
                onChanged: (bool value) {
                  setState(() {
                    isSeriesBook = value;
                  });
                }),
            if (isSeriesBook) ...[
              _buildTextField('Seri Adı', seriesNameController),
              _buildTextField('Kitap Sırası', bookOrderController,
                  keyboardType: TextInputType.number),
            ],
            _buildTextField('Kitap Adı', nameController),
            _buildTextField('Yazar Adı', authorController),
            _buildTextField('Çevirmen', translatorController),
            _buildTextField('Kategori', categoryController),
            _buildTextField('Yayınevi', publishingController),
            _buildTextField('Baskı Yılı', publicationYearController,
                keyboardType: TextInputType.number),
            _buildTextField('Kitap Kapak Resmi', imageController),
            SizedBox(height: 10),
            ImageSection(
              controller: imageController,
            ),
            SizedBox(height: 20),
            Text(
              "Başlama Tarihi: ${widget.book.startedDate == null ? 'Seçilmedi' : DateFormat('dd.MM.yyyy').format(widget.book.startedDate!)}",
              style: TextStyle(fontSize: 17),
            ),
            Row(
              children: [
                BookDatePicker(onDateSelected: (DateTime date) {
                  setState(() {
                    startedDateController = date;
                    isStartedDateCleared = false;
                  });
                }),
                Spacer(),
                Text("Tarihi Sil"),
                IconButton(
                    onPressed: () {
                      setState(() {
                        startedDateController = null;
                        isStartedDateCleared = true;
                      });
                    },
                    icon: Icon(Icons.delete)),
              ],
            ),
            SizedBox(height: 10),
            Text(
              "Bitiş Tarihi: ${widget.book.finishedDate == null ? 'Seçilmedi' : DateFormat('dd.MM.yyyy').format(widget.book.finishedDate!)}",
              style: TextStyle(fontSize: 17),
            ),
            Row(
              children: [
                BookDatePicker(onDateSelected: (DateTime date) {
                  setState(() {
                    finishedDateController = date;
                    isFinishedDateCleared = false;
                  });
                }),
                Spacer(),
                Text("Tarihi Sil"),
                IconButton(
                  onPressed: () {
                    setState(() {
                      finishedDateController = null;
                      isFinishedDateCleared = true;
                    });
                  },
                  icon: Icon(Icons.delete),
                ),
              ],
            ),
            if (isStartedDateCleared)
              Text("Başlama Tarihi silindi. Lütfen 'Kaydet' tuşuna basın."),
            if (isFinishedDateCleared)
              Text("Bitirme Tarihi silindi. Lütfen 'Kaydet' tuşuna basın."),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _saveChanges(firebaseService);
              },
              style: ElevatedButton.styleFrom(
                  side: BorderSide(
                      color: const Color.fromARGB(255, 240, 117, 80),
                      width: 2.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  )),
              child: Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration:
            InputDecoration(labelText: label, border: OutlineInputBorder()),
      ),
    );
  }

  Future<void> _saveChanges(FirebaseServiceBooks firebaseService) async {
    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kullanıcı oturumu bulunamadı.")));
      return;
    }

    final updatedBook = widget.book.copyWith(
      name: nameController.text.trim(),
      author: authorController.text.trim(),
      translator: translatorController.text.trim().isEmpty
          ? null
          : translatorController.text.trim(),
      category: categoryController.text.trim().isEmpty
          ? null
          : categoryController.text.trim(),
      publishing: publishingController.text.trim().isEmpty
          ? null
          : publishingController.text.trim(),
      publicationYear: publicationYearController.text.trim().isEmpty
          ? null
          : int.tryParse(publicationYearController.text.trim()),
      image: imageController.text.trim().isEmpty
          ? null
          : imageController.text.trim(),
      startedDate: isStartedDateCleared
          ? null
          : (startedDateController ?? widget.book.startedDate),
      finishedDate: isFinishedDateCleared
          ? null
          : (finishedDateController ?? widget.book.finishedDate),
    );

    // Silinmesi gereken alanları belirliyoruz
    final fieldsToDelete = <String, dynamic>{};
    if (translatorController.text.trim().isEmpty) {
      fieldsToDelete['translator'] = FieldValue.delete();
    }
    if (categoryController.text.trim().isEmpty) {
      fieldsToDelete['category'] = FieldValue.delete();
    }
    if (publishingController.text.trim().isEmpty) {
      fieldsToDelete['publishing'] = FieldValue.delete();
    }
    if (publicationYearController.text.trim().isEmpty) {
      fieldsToDelete['publicationYear'] = FieldValue.delete();
    }
    if (imageController.text.trim().isEmpty) {
      fieldsToDelete['image'] = FieldValue.delete();
    }
    if (isStartedDateCleared) {
      fieldsToDelete['startedDate'] = FieldValue.delete();
    }
    if (isFinishedDateCleared) {
      fieldsToDelete['finishedDate'] = FieldValue.delete();
    }

    try {
      if (isSeriesBook) {
        final seriesName = seriesNameController.text.trim();
        final bookOrder =
            int.tryParse(bookOrderController.text.trim()) ?? 1; //0
        final seriesId = widget.book is Series
            ? (widget.book as Series).seriesId
            : widget.book.id!;

        final seriesBook = Series(
          id: widget.book.id,
          name: updatedBook.name,
          author: updatedBook.author,
          translator: updatedBook.translator,
          category: updatedBook.category,
          publishing: updatedBook.publishing,
          publicationYear: updatedBook.publicationYear,
          image: updatedBook.image,
          isRead: updatedBook.isRead,
          isStarred: updatedBook.isStarred,
          startedDate: updatedBook.startedDate,
          finishedDate: updatedBook.finishedDate,
          seriesName: seriesName,
          bookOrder: bookOrder,
          seriesId: seriesId,
          type: "series",
          userId: userId,
        );

        // Seri kitap için güncelleme ve silme işlemi
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('series')
            .doc(seriesBook.id)
            .update({...seriesBook.toMap(), ...fieldsToDelete});
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('books')
            .doc(updatedBook.id)
            .update({...updatedBook.toMap(), ...fieldsToDelete});
      }

      ref.invalidate(bookDetailProvider);

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print("Firestore güncelleme hatası: $e");
    }
  }
}

import 'package:bookcase/utils/pick_photos.dart';

import 'package:bookcase/models/book.dart';
import 'package:bookcase/providers/firebase_service_provider.dart';
import 'package:bookcase/utils/book_date_picker.dart';
import 'package:bookcase/utils/series_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddBookScreen extends ConsumerStatefulWidget {
  const AddBookScreen({super.key});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookState();
}

class _AddBookState extends ConsumerState<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookNameController = TextEditingController();
  final _authorController = TextEditingController();
  final _translatorController = TextEditingController();
  final _categoryController = TextEditingController();
  final _publishingController = TextEditingController();
  final _publicationYearController = TextEditingController();
  final _imageController = TextEditingController();
  bool _isRead = false;
  bool isSeriesBook = false;
  String? selectedSeriesId;
  DateTime? startedDate;
  DateTime? finishedDate;
  String? _localImagePath;

  @override
  void dispose() {
    _bookNameController.dispose();
    _authorController.dispose();
    _translatorController.dispose();
    _categoryController.dispose();
    _publishingController.dispose();
    _publicationYearController.dispose();
    _imageController.dispose();

    super.dispose();
  }

  Future<void> _saveBook() async {
    if (_formKey.currentState!.validate()) {
      final firebaseService = ref.read(firebaseServicesProvider);
      final user = ref.read(firebaseAuthProvider).currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Kullanıcı oturumu açık değil.")));
        return;
      }

      final newBook = Book(
        name: _bookNameController.text,
        author: _authorController.text,
        translator: _translatorController.text.isNotEmpty
            ? _translatorController.text
            : null,
        category: _categoryController.text.isNotEmpty
            ? _categoryController.text
            : null,
        publishing: _publishingController.text.isNotEmpty
            ? _publishingController.text
            : null,
        publicationYear: _publicationYearController.text.isNotEmpty
            ? int.tryParse(_publicationYearController.text)
            : null,
        image: _localImagePath != null && _localImagePath!.isNotEmpty
            ? _localImagePath
            : (_imageController.text.isNotEmpty ? _imageController.text : null),
        isRead: _isRead,
        userId: user.uid,
        startedDate: startedDate,
        finishedDate: finishedDate,
      );

      if (isSeriesBook && selectedSeriesId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lütfen seri bilgilerini ekleyin')),
        );
        return;
      }
      try {
        await firebaseService.booksService.addBook(newBook);

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Kitap başarıyla eklendi!")));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kitap Ekle'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
            key: _formKey,
            child: ListView(
              children: [
                SwitchListTile(
                    title: Text("Bu kitap bir serinin parçası mı?"),
                    value: isSeriesBook,
                    onChanged: (bool value) {
                      setState(() {
                        isSeriesBook = value;
                      });
                    }),
                if (isSeriesBook)
                  ElevatedButton(
                      onPressed: () => _showSeriesDialog(context),
                      child: Text('Seri Bilgilerini Gir')),
                SizedBox(height: 10),
                ElevatedButton(onPressed: _saveBook, child: Text('Kaydet')),
                TextFormField(
                  controller: _bookNameController,
                  decoration: InputDecoration(labelText: 'Kitap Adı'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen kitap adını giriniz.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _authorController,
                    decoration: InputDecoration(labelText: 'Yazar Adı'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen yazar adını giriniz.';
                      }
                      return null;
                    }),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _translatorController,
                  decoration: const InputDecoration(
                    labelText: 'Çevirmen',
                    hintText:
                        'Opsiyonel: Varsa kitabın çevirmen(ler)ini giriniz',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    hintText: 'Opsiyonel: Kitabın kategorisini giriniz',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _publishingController,
                  decoration: InputDecoration(
                      labelText: 'Yayın Evi',
                      hintText: 'Opsiyonel: Kitabın yayın evini giriniz'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _publicationYearController,
                  decoration: const InputDecoration(
                    labelText: 'Yayımlanma Tarihi',
                    hintText: 'Opsiyonel: Kitabın yayımlanma tarihini giriniz',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _imageController,
                  decoration: const InputDecoration(
                    labelText: 'Resim URL',
                    hintText:
                        'Opsiyonel: Kitap kapak fotoğrafının URL\' sini giriniz',
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                    child: Text(
                  "--- ya da ---",
                  style: TextStyle(fontSize: 15),
                )),
                const SizedBox(height: 10),
                PickPhotos(
                  onImagePicked: (path) {
                    _localImagePath = path;
                  },
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "Başlama Tarihi",
                      style: TextStyle(fontSize: 17),
                    ),
                    BookDatePicker(onDateSelected: (date) {
                      setState(() {
                        startedDate = date;
                      });
                    }),
                    const SizedBox(height: 10),
                    Text(
                      "Bitiş Tarihi",
                      style: TextStyle(
                        fontSize: 17,
                      ),
                    ),
                    BookDatePicker(onDateSelected: (date) {
                      setState(() {
                        finishedDate = date;
                      });
                    }),
                    const SizedBox(height: 10),
                  ],
                ),
                Divider(),
                SwitchListTile(
                    title: Text(
                      'Okundu mu?',
                      style: TextStyle(fontSize: 17),
                    ),
                    value: _isRead,
                    onChanged: (value) {
                      setState(() {
                        _isRead = value;
                      });
                    }),
                Divider(),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: _saveBook, child: Text('Kaydet')),
              ],
            )),
      ),
    );
  }

  Future<void> _showSeriesDialog(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (context) => SeriesDialog(onSeriesSelected: (seriesId) {
              setState(() {
                selectedSeriesId = seriesId;
              });
            }));
  }
}

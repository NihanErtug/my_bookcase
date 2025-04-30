import 'package:bookcase/models/chapter.dart';
import 'package:bookcase/providers/firebase_service_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddChapter extends ConsumerWidget {
  final String bookId;
  const AddChapter({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterNameController = TextEditingController();
    final chapterOrderContoroller = TextEditingController();
    final chapterContentController = TextEditingController();
    final chapterNoteController = TextEditingController();

    final chapterList = ref.watch(chapterListProvider);

    void saveChapterWithOrder(int order) {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      final newChapter = Chapter(
        name: chapterNameController.text,
        bookId: bookId,
        order: order,
        chapterContent: chapterContentController.text,
        note: chapterNoteController.text,
        userId: userId,
      );

      ref
          .read(firebaseServicesProvider)
          .chaptersService
          .addChapter(bookId, newChapter, ref)
          .then((_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Bölüm başarıyla eklendi.")));

        ref.refresh(chapterListProvider);

        Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Hata: $error")));
      });
    }

    void saveChapter() {
      if (chapterNameController.text.isEmpty ||
          chapterOrderContoroller.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Bölüm adı ve numarası boş olamaz")));
        return;
      }

      final order = int.tryParse(chapterOrderContoroller.text);
      if (order == null || order <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Geçerli bir bölüm numarası giriniz.")));
        return;
      }

      // Mevcut bölümleri kontrol et
      final existingChapters =
          chapterList.whenData((chapters) => chapters).value ?? [];
      final maxOrder = existingChapters.isEmpty
          ? 0
          : existingChapters
              .map((c) => c.order)
              .reduce((a, b) => a > b ? a : b);

      if (order > maxOrder + 1) {
        // Sıra atlanıyorsa kullanıcıya onay sor
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Sıra Atlama Uyarısı"),
            content: Text(
                "Bölüm numarası sırayı atlıyor. Devam etmek istiyor musunuz?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("İptal"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  saveChapterWithOrder(order);
                },
                child: Text("Evet"),
              ),
            ],
          ),
        );
      } else {
        saveChapterWithOrder(order);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Bölüm Ekle'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              chapterList.when(
                data: (chapters) {
                  if (chapters.isEmpty) {
                    return Text("Henüz bölüm eklenmemiş.");
                  }
                  final maxOrder = chapters.isNotEmpty
                      ? chapters
                          .map((c) => c.order)
                          .reduce((a, b) => a > b ? a : b)
                      : 0;
                  return Text(
                    "Son eklenen bölüm numarası: $maxOrder",
                    style: Theme.of(context).textTheme.bodyLarge,
                  );
                },
                loading: () => CircularProgressIndicator(),
                error: (error, stackTrace) => Text("Hata: $error"),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: chapterOrderContoroller,
                decoration: InputDecoration(labelText: 'Bölüm Numarası'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: chapterNameController,
                decoration: InputDecoration(labelText: 'Bölüm Adı'),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: chapterContentController,
                decoration: InputDecoration(labelText: 'Bölüm İçeriği'),
                maxLines: 5,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: chapterNoteController,
                decoration: InputDecoration(labelText: 'Notlar (isteğe bağlı)'),
                maxLines: 2,
              ),
              SizedBox(height: 20),
              Center(
                  child: ElevatedButton(
                      onPressed: saveChapter, child: Text('Kaydet'))),
            ],
          ),
        ),
      ),
    );
  }
}

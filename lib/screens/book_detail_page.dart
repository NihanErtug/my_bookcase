import 'package:bookcase/models/book.dart';
import 'package:bookcase/models/chapter.dart';
import 'package:bookcase/models/note.dart';
import 'package:bookcase/models/series.dart';
import 'package:bookcase/providers/firebase_service_provider.dart';

import 'package:bookcase/screens/add_chapter.dart';
import 'package:bookcase/screens/book_edit_page.dart';
import 'package:bookcase/screens/book_list_page.dart';
import 'package:bookcase/screens/chapter_page.dart';
import 'package:bookcase/screens/home_page.dart';
import 'package:bookcase/screens/series_list_page.dart';
import 'package:bookcase/utils/build_trailing_icons_image.dart';

import 'package:bookcase/utils/popup_menu_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';

class BookDetailPage extends ConsumerStatefulWidget {
  final String bookId;

  const BookDetailPage({required this.bookId, super.key});

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    final bookDetailAsyncValue =
        ref.watch(bookDetailProvider((widget.bookId, userId)));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: bookDetailAsyncValue.when(
          data: (book) => Text(book?.name ?? 'Kitap Detayı'),
          error: (error, stack) => Text("Hata: $error"),
          loading: () => Text('Yükleniyor'),
        ),
        actions: bookDetailAsyncValue.maybeWhen(
            data: (book) => book != null
                ? [
                    buildPopupMenuButton(
                      context: context,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookEditPage(book: book),
                          ),
                        );
                      },
                      onDelete: () {
                        _confirmDeleteBook(context, ref, book);
                      },
                    ),
                  ]
                : null,
            orElse: () => null),
      ),
      body: bookDetailAsyncValue.when(
          data: (book) => book != null
              ? _buildBookDetail(context, ref, book, userId)
              : Center(
                  child: Text('Kitap bulunamadı.'),
                ),
          error: (error, stack) => Center(
                child: Text("Hata: $error"),
              ),
          loading: () => Center(
                child: CircularProgressIndicator(),
              )),
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: Colors.deepOrangeAccent,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.note_add,
                color: Color.fromARGB(255, 231, 120, 86)),
            label: 'Not Ekle',
            onTap: () {
              _addNoteDialog(context, ref, userId);
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.add_circle,
                color: Color.fromARGB(255, 231, 120, 86)),
            label: 'Bölüm Ekle',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AddChapter(bookId: widget.bookId)));
            },
          ),
        ],
      ),
    );
  }

  String get userId => _userId;
}

Widget _buildBookDetail(
    BuildContext context, WidgetRef ref, Book book, String userId) {
  return SingleChildScrollView(
    padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNavigate(context, book),
        SizedBox(height: 16.0),
        _buildBookInfo(book, context),
        if (book.startedDate != null || book.finishedDate != null)
          SizedBox(height: 16.0),
        if (book.startedDate != null)
          Text(
              style: Theme.of(context).textTheme.titleMedium,
              'Başlama Tarihi: ${DateFormat('dd.MM.yyyy').format(book.startedDate!)}'),
        SizedBox(height: 8.0),
        if (book.finishedDate != null)
          Text(
              style: Theme.of(context).textTheme.titleMedium,
              'Bitiriş Tarihi: ${DateFormat('dd.MM.yyyy').format(book.finishedDate!)}'),
        SizedBox(height: 16.0),
        _buildChapterSection(context, ref, book),
        SizedBox(height: 16.0),
        if (book is Series) buildTrailingIcons(context, ref, book),
        SizedBox(height: 16.0),
        _buildNotesSection(context, ref, book, userId),
        SizedBox(height: 16.0),
      ],
    ),
  );
}

Row _buildNavigate(BuildContext context, Book book) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      GestureDetector(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => HomePage()));
        },
        child: Text("Ana Sayfa ",
            style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 16,
                decoration: TextDecoration.underline)),
      ),
      Text("  |  ", style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
      GestureDetector(
        onTap: () {
          if (book is Series) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SeriesListPage()));
          } else {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => BookListPage()));
          }
        },
        child: Text(" Kitap Listesi",
            style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 16,
                decoration: TextDecoration.underline)),
      ),
    ],
  );
}

Widget _buildBookInfo(Book book, BuildContext context) {
  final details = [
    if (book is Series) 'Seri Adı: ${book.seriesName}',
    (book is Series)
        ? 'Kitap Adı: ${book.name} (${book.bookOrder}. kitap)'
        : 'Kitap Adı: ${book.name}',
    'Yazar: ${book.author}',
    if (book.translator != null) 'Çevirmen: ${book.translator}',
    if (book.publicationYear != null) 'Baskı Yılı: ${book.publicationYear}',
    if (book.publishing != null) 'Yayınevi: ${book.publishing}',
    if (book.category != null) 'Kategori: ${book.category}',
  ];
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      buildImage(book.image, context),
      SizedBox(width: 10),
      Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: details
            .map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    detail,
                    softWrap: true,
                  ),
                ))
            .toList(),
      )),
    ],
  );
}

Widget _buildChapterSection(BuildContext context, WidgetRef ref, Book book) {
  final chapterListAsyncValue = ref.watch(chapterListProvider);

  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      chapterListAsyncValue.when(
        data: (chapters) => Text(
          'Bölümler (${chapters.length}):',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        loading: () => CircularProgressIndicator(),
        error: (error, stackTrace) => Text("Hata: $error"),
      ),
      SizedBox(width: 20),
      ElevatedButton(
        onPressed: () {
          _showChaptersModal(context, ref, chapterListAsyncValue, book);
        },
        child: Text('Bölümleri Görüntüle'),
      ),
    ],
  );
}

Widget _buildNotesSection(
    BuildContext context, WidgetRef ref, Book book, String userId) {
  final bookNotesAsyncValue = ref.watch(getBookNotesProvider);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Kitap Notları', style: Theme.of(context).textTheme.titleLarge),
      SizedBox(height: 5),
      Divider(),
      bookNotesAsyncValue.when(
          data: (notes) => Column(
                children: notes
                    .map((note) => _bulidNoteTile(context, ref, note, userId))
                    .toList(),
              ),
          error: (error, stack) => Text('Hata: $error'),
          loading: () => Center(child: CircularProgressIndicator())),
      SizedBox(height: 40),
    ],
  );
}

Widget _bulidNoteTile(
    BuildContext context, WidgetRef ref, Note note, String userId) {
  return ListTile(
    title: Text(
      note.content,
      style: TextStyle(fontSize: 15),
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<String>(
          icon: Icon(Icons.arrow_drop_down),
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text("Düzenle"),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18),
                    SizedBox(width: 8),
                    Text("Sil"),
                  ],
                ),
              ),
            ];
          },
          onSelected: (value) {
            if (value == 'edit') {
              _showEditNoteDialog(context, ref, note, userId);
            } else if (value == 'delete') {
              _confirmDeleteNote(context, ref, note, userId);
            }
          },
        ),
      ],
    ),
  );
}

void _showEditNoteDialog(
    BuildContext context, WidgetRef ref, Note note, String userId) {
  final controller = TextEditingController(text: note.content);

  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text("Notu Düzenle"),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Not içeriği'),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("İptal")),
              TextButton(
                  onPressed: () async {
                    final updatedContent = controller.text;

                    if (updatedContent != note.content) {
                      // eğer içerik değiştiyse
                      final updatedNote =
                          note.copyWith(content: updatedContent);

                      await ref
                          .read(firebaseServicesProvider)
                          .notesService
                          .updateNote(userId, note.bookId!, updatedNote);
                      Navigator.pop(context);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Güncelle")),
            ],
          ));
}

void _showChaptersModal(BuildContext context, WidgetRef ref,
    AsyncValue<List<Chapter>> chapters, Book book) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // ilk açıldığında %50
          minChildSize: 0.2,
          maxChildSize: 0.9,
          expand: false, // tam ekran olmasını engeller
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: chapters.when(
                  data: (chapterList) {
                    if (chapterList.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Henüz herhangi bir bölüm eklenmemiş.",
                            style: TextStyle(
                                fontSize: 16, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    // eksik bölümler için
                    final completeChapters = fillMissingChapters(chapterList);

                    return ListView.builder(
                        controller: scrollController,
                        itemCount: completeChapters.length,
                        itemBuilder: (context, index) {
                          final chapter = completeChapters[index];

                          return InkWell(
                            onTap: chapter.isPlaceholder
                                ? null
                                : () async {
                                    final updatedChapter = chapter.copyWith(
                                        isRead: !chapter.isRead);

                                    await ref
                                        .read(firebaseServicesProvider)
                                        .chaptersService
                                        .updateChapterReadStatus(
                                            chapter.bookId,
                                            chapter.id!,
                                            chapter.readed,
                                            updatedChapter.isRead);

                                    ref.invalidate(chapterListProvider);

                                    Navigator.pop(context);

                                    final selectedChapter =
                                        chapterList.firstWhere(
                                      (c) => c.id == updatedChapter.id,
                                      orElse: () => chapterList.first,
                                    );

                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => ChapterPage(
                                                  chapter: selectedChapter,
                                                  book: book,
                                                )));
                                  },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: ListTile(
                                    title: Text(
                                      '${chapter.order}. ${chapter.name}',
                                      style: TextStyle(
                                        color: chapter.isPlaceholder
                                            ? Colors.grey
                                            : (chapter.isRead
                                                ? Colors.greenAccent
                                                : null),
                                        fontWeight: chapter.isRead
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontStyle: chapter.isPlaceholder
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    chapter.isPlaceholder
                                        ? 'İçerik eklenmemiş'
                                        : (chapter.note ??
                                            'Bu bölüme ait not yok.'),
                                    style:
                                        TextStyle(fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                  },
                  error: (error, stack) => Center(child: Text("Hata: $error")),
                  loading: () => Center(
                        child: CircularProgressIndicator(),
                      )),
            );
          },
        );
      });
}

List<Chapter> fillMissingChapters(List<Chapter> chapterList) {
  if (chapterList.isEmpty) return [];

  final maxOrder =
      chapterList.map((c) => c.order).reduce((a, b) => a > b ? a : b);
  final completeList = List.generate(maxOrder, (index) {
    final chapter = chapterList.firstWhere((c) => c.order == index + 1,
        orElse: () => Chapter.empty(index + 1));
    return chapter;
  });
  return completeList;
}

void _confirmDeleteBook(BuildContext context, WidgetRef ref, Book book) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text('Kitabı Sil'),
            content: Text("Bu kitabı silmek istediğinizden emin misiniz?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("İptal")),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  await ref
                      .read(firebaseServicesProvider)
                      .booksService
                      .deleteBook(book.id!);
                },
                child: Text("Sil"),
              ),
            ],
          ));
}

void _confirmDeleteNote(
    BuildContext context, WidgetRef ref, Note note, String userId) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text("Notu Sil"),
            content: Text("Bu notu silmek istediğinizden emin misiniz?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("İptal"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref
                      .read(firebaseServicesProvider)
                      .notesService
                      .deleteBookNote(userId, note.bookId!, note.id!);
                },
                child: Text("Sil"),
              ),
            ],
          ));
}

void _addNoteDialog(BuildContext context, WidgetRef ref, String userId) {
  final noteController = TextEditingController();

  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text('Yeni Not Ekle'),
            content: TextField(
              controller: noteController,
              decoration: InputDecoration(hintText: 'Not içeriğini girin'),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("İptal"),
              ),
              TextButton(
                onPressed: () async {
                  final newNote = Note(
                      content: noteController.text,
                      bookId: ref.read(bookIdProvider));
                  Navigator.pop(context);
                  await ref
                      .read(firebaseServicesProvider)
                      .notesService
                      .addNote(userId, newNote.bookId!, newNote);
                },
                child: Text("Ekle"),
              ),
            ],
          ));
}

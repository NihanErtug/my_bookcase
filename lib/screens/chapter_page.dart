import 'package:bookcase/models/book.dart';
import 'package:bookcase/providers/firebase_service_provider.dart';
import 'package:bookcase/providers/theme_notifier.dart';
import 'package:bookcase/screens/book_detail_page.dart';

import 'package:bookcase/screens/home_page.dart';
import 'package:bookcase/utils/popup_menu_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chapter.dart';

class ChapterPage extends ConsumerWidget {
  final Chapter chapter;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final Book book;

  ChapterPage({super.key, required this.chapter, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ValueNotifier<bool> showScrollUp = ValueNotifier(false);
    final ValueNotifier<bool> showScrollDown = ValueNotifier(false);
    double previousOffSet = 0;
    DateTime previousTime = DateTime.now();

    final user = ref.watch(firebaseAuthProvider).currentUser;
    final userId = user?.uid;

    if (userId == null) {
      return Scaffold(
        body: Center(child: Text("Kullanıcı bulunamadı.")),
      );
    }

    final bookId = chapter.bookId;
    final chapterStream =
        ref.watch(firebaseServicesProvider).chaptersService.getChapters(bookId);

    void handleScroll(ScrollNotification notification) {
      if (notification is ScrollUpdateNotification) {
        final currentOffSet = notification.metrics.pixels;
        final currentTime = DateTime.now();
        final offsetDiff = (currentOffSet - previousOffSet).abs();
        final timeDiff = currentTime.difference(previousTime).inMilliseconds;
        final scrollSpeed = timeDiff > 0 ? offsetDiff / timeDiff : 0;
        const speedThreshold = 1.5;

        if (scrollSpeed > speedThreshold) {
          if (currentOffSet > previousOffSet) {
            showScrollDown.value = true;
            showScrollUp.value = false;
          } else {
            showScrollUp.value = true;
            showScrollDown.value = false;
          }

          Future.delayed(const Duration(seconds: 4), () {
            showScrollDown.value = false;
            showScrollUp.value = false;
          });
        }

        previousOffSet = currentOffSet;
        previousTime = currentTime;
      }
    }

    return StreamBuilder<List<Chapter>>(
      stream: chapterStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Hiç bölüm eklenmemiş.'));
        }

        final chapterList = snapshot.data!;

        final currentChapter = chapterList.firstWhere((c) => c.id == chapter.id,
            orElse: () => chapterList.first);

        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildChapterDrawer(context, ref, chapterList, book),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.white30,
            foregroundColor: Colors.deepOrange,
            onPressed: () {
              _chapterSettingsModal(context, ref);
            },
            mini: true,
            child: Icon(Icons.keyboard_arrow_up),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.miniStartDocked,
          body: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  handleScroll(notification);
                  return true;
                },
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverAppBar(
                        automaticallyImplyLeading: false,
                        expandedHeight: 50.0,
                        floating: true,
                        flexibleSpace: FlexibleSpaceBar(
                          title: Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(currentChapter.name),
                          ),
                        ),
                        actions: [
                          IconButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => BookDetailPage(
                                            bookId: chapter.bookId)));
                              },
                              icon: Icon(Icons.menu_book_rounded)),
                          buildPopupMenuButton(
                              context: context,
                              onEdit: () {
                                _editChapter(context, ref);
                              },
                              onDelete: () {
                                _confirmDelete(context, ref);
                              }),
                        ],
                      ),
                      SliverList(
                        delegate: SliverChildListDelegate([
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Bölüm: ${currentChapter.order}',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              currentChapter.chapterContent,
                              style: TextStyle(
                                  fontSize:
                                      ref.watch(fontSettingsProvider).fontSize,
                                  fontFamily: ref
                                      .watch(fontSettingsProvider)
                                      .fontFamily),
                              textAlign:
                                  TextAlign.justify, // metini düzenli hizalar
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Bölüm Notu:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  currentChapter.note ??
                                      "Bu bölüme ait not yok",
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          _buildNavigationControls(ref, chapterList, context),
                          SizedBox(height: 100),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              // Yukarı Ok
              ValueListenableBuilder<bool>(
                  valueListenable: showScrollUp,
                  builder: (context, value, child) {
                    if (!value) return const SizedBox.shrink();
                    return Positioned(
                      top: MediaQuery.of(context).size.height / 2 - 50,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => _scrollToTop(),
                        child:
                            Icon(Icons.arrow_upward, color: Colors.deepOrange),
                      ),
                    );
                  }),
              // Aşağı Ok
              ValueListenableBuilder<bool>(
                  valueListenable: showScrollDown,
                  builder: (context, value, child) {
                    if (!value) return const SizedBox.shrink();
                    return Positioned(
                        bottom: MediaQuery.of(context).size.height / 2 - 50,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _scrollToDown(),
                          child: Icon(Icons.arrow_downward,
                              color: Colors.deepOrange),
                        ));
                  })
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationControls(
      WidgetRef ref, List<Chapter> chapterList, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _getPreviousChapter(chapterList) != null
              ? () => _navigateToChapter(
                  ref, _getPreviousChapter(chapterList)!, context)
              : null,
          icon: Icon(Icons.arrow_circle_left_outlined),
          color: _getPreviousChapter(chapterList) != null
              ? Colors.deepOrange.shade300
              : Colors.grey,
        ),
        IconButton(
            onPressed: _getNextChapter(chapterList) != null
                ? () => _navigateToChapter(
                    ref, _getNextChapter(chapterList)!, context)
                : null,
            icon: Icon(Icons.arrow_circle_right_outlined),
            color: _getNextChapter(chapterList) != null
                ? Colors.deepOrange.shade300
                : Colors.grey),
      ],
    );
  }

  void _navigateToChapter(
      WidgetRef ref, Chapter targetChapter, BuildContext context) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ChapterPage(
                  chapter: targetChapter,
                  book: book,
                )));
  }

  void _editChapter(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: chapter.name);
    final contentController =
        TextEditingController(text: chapter.chapterContent);
    final noteController = TextEditingController(text: chapter.note ?? '');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text("Bölümü Düzenle",
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: 'Bölüm Adı'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contentController,
                        decoration: InputDecoration(
                            labelText: 'Bölüm içeriği',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder()),
                        maxLines: null,
                        minLines: 10,
                        keyboardType: TextInputType.multiline,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noteController,
                        decoration: InputDecoration(labelText: 'Not'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('İptal')),
                  ElevatedButton(
                      onPressed: () async {
                        final updatedChapter = chapter.copyWith(
                            name: nameController.text,
                            note: noteController.text,
                            chapterContent: contentController.text);
                        await ref
                            .read(firebaseServicesProvider)
                            .chaptersService
                            .updateChapter(chapter.bookId, updatedChapter);

                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChapterPage(
                                    chapter: updatedChapter, book: book)));
                      },
                      child: Text("Kaydet")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _chapterSettingsModal(BuildContext context, WidgetRef ref) {
    const availableFonts = ['Lora', 'Roboto'];

    final chapterStream = ref
        .watch(firebaseServicesProvider)
        .chaptersService
        .getChapters(chapter.bookId);

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return DraggableScrollableSheet(
              initialChildSize: 0.3,
              minChildSize: 0.1,
              maxChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return StreamBuilder(
                    stream: chapterStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Hata: ${snapshot.error}"));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text("Hiç bölüm eklenmemiş."));
                      }
                      final fontSettings = ref.watch(fontSettingsProvider);
                      final chapterList = snapshot.data!;

                      return Scaffold(
                        drawer: _buildChapterDrawer(
                            context, ref, chapterList, book),
                        body: Container(
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Bölüm: ${chapter.order} - ${chapter.name} ",
                                style: TextStyle(
                                    fontSize: fontSettings.fontSize,
                                    fontFamily: fontSettings.fontFamily),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _scaffoldKey.currentState?.openDrawer();
                                    },
                                    icon: Icon(Icons.list,
                                        color: Colors.green[400]),
                                  ),
                                  IconButton(
                                      icon: Icon(
                                        ref.watch(themeProvider) ==
                                                ThemeMode.light
                                            ? Icons.nightlight_round
                                            : Icons.wb_sunny,
                                        color: Colors.green[300],
                                      ),
                                      onPressed: () {
                                        final themeNotifier =
                                            ref.read(themeProvider.notifier);
                                        final newThemeMode =
                                            ref.watch(themeProvider) ==
                                                    ThemeMode.light
                                                ? ThemeMode.dark
                                                : ThemeMode.light;
                                        themeNotifier.toggleTheme(newThemeMode);
                                      }),
                                  IconButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    HomePage()));
                                      },
                                      icon: Icon(
                                        Icons.home,
                                        color: Colors.green[400],
                                      )),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Font Boyutu: ",
                                    style: TextStyle(color: Colors.green[200]),
                                  ),
                                  IconButton(
                                      onPressed: () => ref
                                          .read(fontSettingsProvider.notifier)
                                          .decreaseFontSize(),
                                      icon: Icon(Icons.remove,
                                          color: Colors.green[200])),
                                  Text('${fontSettings.fontSize.toInt()}',
                                      style:
                                          TextStyle(color: Colors.green[200])),
                                  IconButton(
                                      onPressed: () => ref
                                          .read(fontSettingsProvider.notifier)
                                          .increaseFontSize(),
                                      icon: Icon(Icons.add,
                                          color: Colors.green[200])),
                                  SizedBox(
                                      height: 40,
                                      child: VerticalDivider(
                                        width: 40,
                                        thickness: 2,
                                      )),
                                  DropdownButton<String>(
                                      value: fontSettings.fontFamily,
                                      items: availableFonts.map((String value) {
                                        return DropdownMenuItem<String>(
                                            value: value, child: Text(value));
                                      }).toList(),
                                      style:
                                          TextStyle(color: Colors.green[300]),
                                      onChanged: (newValue) {
                                        if (newValue != null) {
                                          ref
                                              .read(
                                                  fontSettingsProvider.notifier)
                                              .changeFontFamily(newValue);
                                        }
                                      }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    });
              });
        });
  }

  Widget _buildChapterDrawer(BuildContext context, WidgetRef ref,
      List<Chapter> chapterList, Book book) {
    // eksik bölümler için
    final completeChapterList = fillMissingChapters(chapterList);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              book.image != null && book.image!.isNotEmpty
                  ? Image.network(
                      book.image!,
                      fit: BoxFit.contain,
                    )
                  : Image.asset(
                      "assets/pictures/default_pic.png",
                      width: MediaQuery.of(context).size.width * 0.2,
                      height: MediaQuery.of(context).size.width * 0.4,
                    ),
              SizedBox(width: 10),
              Flexible(
                  child: Text(
                book.name,
                softWrap: true, // alt satıra kayma etkin
                overflow: TextOverflow.visible, // taşan metni göster
                style: TextStyle(fontSize: 16),
              )),
            ],
          )),
          Expanded(
              child: ListView.builder(
                  //itemCount: chapterList.length,
                  itemCount: completeChapterList.length,
                  itemBuilder: (context, index) {
                    final chapterItem = completeChapterList[index];

                    return ListTile(
                      leading: chapterItem.isPlaceholder
                          ? Icon(Icons.hourglass_empty, color: Colors.grey)
                          : IconButton(
                              icon: Icon(
                                  chapterItem.readed
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: chapterItem.readed
                                      ? Colors.green
                                      : Colors.grey),
                              onPressed: () =>
                                  toggleReadStatus(context, ref, chapterItem)),
                      title: Text("${chapterItem.order}-  ${chapterItem.name}",
                          style: TextStyle(
                              color: chapterItem.isPlaceholder
                                  ? Colors.grey
                                  : null,
                              fontStyle: chapterItem.isPlaceholder
                                  ? FontStyle.italic
                                  : FontStyle.normal)),
                      onTap: chapterItem.isPlaceholder
                          ? null
                          : () {
                              final selectedchapter =
                                  completeChapterList.firstWhere(
                                (chapter) => chapter.order == chapterItem.order,
                                orElse: () => completeChapterList.first,
                              );

                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ChapterPage(
                                            chapter: selectedchapter,
                                            book: book,
                                          )));
                            },
                    );
                  })),
        ],
      ),
    );
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

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bölümü Sil'),
        content: const Text('Bu bölümü silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(firebaseServicesProvider)
                  .chaptersService
                  .deleteChapter(chapter.bookId, chapter.id!);
              if (Navigator.canPop(context)) Navigator.pop(context);
              if (Navigator.canPop(context)) Navigator.pop(context);

              /* Navigator.pop(context); // AlertDialog kapanır
              Navigator.pop(context); // ChapterPage kapanır */
            },
            child: const Text('Evet'),
          ),
        ],
      ),
    );
  }

  void toggleReadStatus(
      BuildContext context, WidgetRef ref, Chapter chapter) async {
    final firebaseService = ref.read(firebaseServicesProvider);
    final newStatus = !chapter.readed;

    await firebaseService.chaptersService.updateChapterReadStatus(
        chapter.bookId, chapter.id!, newStatus, chapter.isRead);

    ref.invalidate(chapterListProvider);
  }

  Chapter? _getPreviousChapter(List<Chapter> chapterList) {
    final currentChapterIndex = chapter.order;
    if (currentChapterIndex > 1) {
      for (int i = currentChapterIndex - 1; i >= 1; i--) {
        final previousChapter = chapterList.firstWhere(
          (chapter) => chapter.order == i,
          orElse: () => Chapter.empty(i),
        );
        if (!previousChapter.isPlaceholder) {
          return previousChapter;
        }
      }
    }
    return null;
  }

  Chapter? _getNextChapter(List<Chapter> chapterList) {
    final currentChapterIndex = chapter.order;
    if (currentChapterIndex < chapterList.length) {
      for (int i = currentChapterIndex + 1; i <= chapterList.length; i++) {
        final nextChapter = chapterList.firstWhere(
          (chapter) => chapter.order == i,
          orElse: () => Chapter.empty(i),
        );
        if (!nextChapter.isPlaceholder) {
          return nextChapter;
        }
      }
    }
    return null;
  }

  void _scrollToTop() {
    _scrollController.animateTo(0,
        duration: Duration(milliseconds: 500), curve: Curves.easeOut);
  }

  void _scrollToDown() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 500), curve: Curves.easeOut);
  }
}

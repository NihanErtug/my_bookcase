import 'package:bookcase/models/book.dart';
import 'package:bookcase/models/series.dart';
import 'package:bookcase/providers/firebase_service_provider.dart';
import 'package:bookcase/providers/search_filter_notifier.dart';
import 'package:bookcase/screens/book_detail_page.dart';
import 'package:bookcase/screens/book_list_page.dart';
import 'package:bookcase/screens/filtered_book_list_page.dart';
import 'package:bookcase/screens/login_register_page.dart';

import 'package:bookcase/screens/series_list_page.dart';
import 'package:bookcase/screens/settings_page.dart';
import 'package:bookcase/services/auth_service.dart';
import 'package:bookcase/themes/app_colors.dart';

import 'package:bookcase/utils/settings_icon.dart';
import 'package:bookcase/utils/turkishSort.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchFilter = ref.watch(searchFilterProvider);
    final userId = ref.read(firebaseAuthProvider).currentUser?.uid; //
    final books = ref.watch(bookListProvider(userId!)).value ?? []; //
    final filteredBooks = _filterBooks(context, books, searchFilter);

    final currentUserInfoProvider =
        FutureProvider<DocumentSnapshot<Map<String, dynamic>>>((ref) async {
      final auth = ref.watch(authProvider);
      final userId = auth.currentUserId;

      if (userId == null) {
        throw Exception("Kullanıcı oturumu yok");
      }
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc;
    });

    void signOutAndGoToLogin(BuildContext context) async {
      await ref.read(authProvider).signOut();
      ref.invalidate(firebaseServicesProvider); // servisleri sıfırlıyoruz

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginRegisterPage()),
        (route) => false,
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Klavye açıldığında otomatik olarak sayfayı yeniden düzenlemek için
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Kitaplığım"),
        actions: [
          buildSettingsPopupMenuButton(
              onTheme: () {},
              onLogout: () {
                signOutAndGoToLogin(context);
              },
              onSettings: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => SettingsPage()));
              })
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Consumer(builder: (context, ref, child) {
              final userInfoAsync = ref.watch(currentUserInfoProvider);

              return userInfoAsync.when(
                  data: (doc) {
                    final userName = doc.data()?['username'] ?? 'Kullanıcı';
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Hoş geldin $userName",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: AppColors.greenColor),
                      ),
                    );
                  },
                  error: (err, stack) => Text("Hata: ${err.toString()}"),
                  loading: () => CircularProgressIndicator());
            }),
            _buildSearchField((value) {
              ref.read(searchFilterProvider.notifier).updateSearchQuery(value);
            }, ref),
            const SizedBox(height: 30.0),
            Expanded(
                child: SingleChildScrollView(
              child: Column(
                children: [
                  if (searchFilter.searchQuery.isNotEmpty)
                    _buildSearchResults(filteredBooks, ref),
                  _buildFilterOptions(ref),
                  SizedBox(height: 10),
                  _buildYearMonthFilter(searchFilter, ref),
                  const SizedBox(height: 20.0),
                  TextButton(
                      style: TextButton.styleFrom(
                          side: BorderSide(
                              width: 1,
                              color: Colors.deepPurple,
                              style: BorderStyle.solid)),
                      onPressed: () {
                        _navigateToFilteredBooks(
                            ref, searchFilter, context, userId);
                      },
                      child: Text(
                        "Filtrelenmiş kitapları getir",
                        style: TextStyle(color: Colors.grey),
                      )),
                  SizedBox(height: 20),
                  Divider(),
                ],
              ),
            )),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(context),
    );
  }

  Widget _buildSearchField(Function(String) onChanged, WidgetRef ref) {
    final _controller = ref.watch(searchControllerProvider);

    return Padding(
      padding: EdgeInsets.all(8.0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: "Kitap adı, yazar adı, seri adı ara...",
          border: OutlineInputBorder(),
          suffixIcon: IconButton(
              onPressed: () {
                _controller.clear();
                onChanged('');
              },
              icon: Icon(Icons.close)),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildFilterOptions(WidgetRef ref) {
    final searchFilter = ref.watch(searchFilterProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFilterChip(ref, "Okunmuş", searchFilter.showRead, (value) {
          ref.read(searchFilterProvider.notifier).toggleShowRead(value);
        }),
        _buildFilterChip(ref, "Yıldızlı", searchFilter.showStarred, (value) {
          ref.read(searchFilterProvider.notifier).toggleShowStarred(value);
        }),
        _buildFilterChip(ref, "Okunmamış", searchFilter.showUnread, (value) {
          ref.read(searchFilterProvider.notifier).toggleShowUnread(value);
        }),
      ],
    );
  }

  Widget _buildYearMonthFilter(SearchFilterState searchFilter, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        DropdownButton<int?>(
            value: searchFilter.selectedYear,
            hint: Text("Yıl"),
            items: List.generate(30, (index) {
              final year = DateTime.now().year - index;
              return DropdownMenuItem(value: year, child: Text("$year"));
            }),
            onChanged: (value) {
              ref.read(searchFilterProvider.notifier).updateYear(value);
            }),
        DropdownButton<int?>(
            value: searchFilter.selectedMonth,
            hint: Text("Ay"),
            items: List.generate(12, (index) {
              return DropdownMenuItem(
                  value: index + 1, child: Text("${index + 1}"));
            }),
            onChanged: (value) {
              ref.read(searchFilterProvider.notifier).updateMonth(value);
            }),
        IconButton(
            tooltip: "Tarihi Sıfırla",
            onPressed: () {
              ref.read(searchFilterProvider.notifier).resetFilters();
            },
            icon: Icon(Icons.clear)),
      ],
    );
  }

  Widget _buildFilterChip(WidgetRef ref, String label, bool selected,
      ValueChanged<bool> onSelected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      side: BorderSide(
        color: Colors.deepPurple,
      ),
      selectedColor: AppColors.greenColor,
    );
  }

  void _navigateToFilteredBooks(WidgetRef ref, SearchFilterState searchFilter,
      BuildContext context, String userId) {
    if (searchFilter.showRead && searchFilter.showUnread) {
      ref.read(searchFilterProvider.notifier).resetFilters();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => BookListPage()));
      });
    }
    final books = ref.read(bookListProvider(userId)).value ?? [];
    final filteredBooks = _filterBooks(context, books, searchFilter);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => FilteredBookListPage(
                  filteredBooks: filteredBooks,
                  searchFilter: searchFilter,
                )));

    ref.read(searchFilterProvider.notifier).updateSearchQuery('');
  }

  Widget _buildSearchResults(List<Book> filteredBooks, WidgetRef ref) {
    final sortedBooks = List<Book>.from(filteredBooks)
      ..sort((a, b) {
        if (a is Series && b is Series) {
          return turkishSort(a.seriesName, b.seriesName);
        } else if (a is Series) {
          return turkishSort(a.seriesName, b.name);
        } else if (b is Series) {
          return turkishSort(a.name, b.seriesName);
        } else {
          return turkishSort(a.name, b.name);
        }
      });

    if (filteredBooks.isEmpty) {
      return Center(
        child: Text(
          "Eşleşen kitap bulunamadı.\n",
          style: TextStyle(fontSize: 16, color: Colors.redAccent),
        ),
      );
    }
    return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: sortedBooks.length,
        itemBuilder: (context, index) {
          final book = sortedBooks[index];
          return ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book is Series
                    ? 'Seri adı: ${book.seriesName}'
                    : book.name),
                if (book is Series)
                  Text('${book.name} (${book.bookOrder}. Kitap)',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                Text("Yazar: ${book.author}",
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            onTap: () async {
              ref.read(bookIdProvider.notifier).state = book.id!;
              final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BookDetailPage(bookId: book.id!)));
              if (result == true) {
                ref.read(searchFilterProvider.notifier).resetFilters();
              }
            },
          );
        });
  }

  List<Book> _filterBooks(
      BuildContext context, List<Book> books, SearchFilterState searchFilter) {
    return books.where((book) {
      final matchesSearch = book.name
              .toLowerCase()
              .contains(searchFilter.searchQuery.toLowerCase()) ||
          book.author
              .toLowerCase()
              .contains(searchFilter.searchQuery.toLowerCase()) ||
          (book is Series &&
              book.seriesName
                  .toLowerCase()
                  .contains(searchFilter.searchQuery.toLowerCase()));

      final matchesStarred = searchFilter.showStarred ? book.isStarred : true;
      final matchesRead = searchFilter.showRead ? book.isRead : true;
      final matchesUnread = searchFilter.showUnread ? !book.isRead : true;

      final matchesReadStatus =
          (searchFilter.showRead && searchFilter.showUnread)
              ? true
              : (matchesRead && matchesUnread);

      final matchesYear = searchFilter.selectedYear != null
          ? (book.startedDate?.year == searchFilter.selectedYear)
          : true;

      final matchesMonth = searchFilter.selectedMonth != null
          ? (book.startedDate?.month == searchFilter.selectedMonth)
          : true;

      return matchesSearch &&
          matchesStarred &&
          matchesReadStatus &&
          matchesYear &&
          matchesMonth;
    }).toList();
  }
}

Widget _buildBottomButton(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withAlpha(70),
          spreadRadius: 5,
          blurRadius: 7,
          offset: Offset(0, 3),
        ),
      ],
    ),
    padding: EdgeInsets.all(16),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => BookListPage()));
          },
          child: Text(
            "Kitaplara Git",
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.bold, color: AppColors.greenColor),
          ),
        ),
        SizedBox(width: 10),
        Icon(Icons.book, size: 30, color: AppColors.greenColor),
        SizedBox(
            height: 60,
            child: VerticalDivider(
              width: 40,
              thickness: 3,
            )),
        Icon(Icons.collections_bookmark, size: 30, color: AppColors.greenColor),
        SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SeriesListPage()));
          },
          child: Text(
            "Serilere Git",
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.bold, color: AppColors.greenColor),
          ),
        ),
      ],
    ),
  );
}

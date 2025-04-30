import 'package:bookcase/models/book.dart';
import 'package:bookcase/models/series.dart';
import 'package:bookcase/providers/firebase_service_provider.dart';
import 'package:bookcase/providers/search_filter_notifier.dart';

import 'package:bookcase/screens/book_detail_page.dart';
import 'package:bookcase/themes/app_colors.dart';
import 'package:bookcase/utils/turkishSort.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilteredBookListPage extends ConsumerWidget {
  final List<Book> filteredBooks;
  final SearchFilterState searchFilter;

  const FilteredBookListPage(
      {super.key, required this.filteredBooks, required this.searchFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text("Filtrelenmiş Kitaplar"),
      ),
      body: Column(
        children: [
          _buildFilterInfo(context),
          Divider(height: 20),
          Expanded(
            child: ListView.builder(
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
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey)),
                        Text('Yazar: ${book.author}',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    onTap: () {
                      ref.read(bookIdProvider.notifier).state = book.id!;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  BookDetailPage(bookId: book.id!)));
                    },
                  );
                }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterInfo(BuildContext context) {
    final List<String> activeFilters = [];

    if (searchFilter.showStarred) {
      activeFilters.add("Yıldızladıklarım");
    }
    if (searchFilter.showRead) {
      activeFilters.add("Okuduklarım");
    }
    if (searchFilter.showUnread) {
      activeFilters.add("Okumadıklarım");
    }
    if (searchFilter.selectedYear != null) {
      activeFilters.add(
          "${searchFilter.selectedYear} Yılında Okunmaya Başlanan Kitaplar");
    }
    if (searchFilter.selectedMonth != null) {
      activeFilters.add(
          "${searchFilter.selectedMonth}. Ayda Okunmaya Başlanan Kitaplar");
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeFilters.isNotEmpty)
            Text(activeFilters.join(", "),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: AppColors.greenColor))
          else
            Text("Hiçbir filtre uygulanmadı.",
                style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

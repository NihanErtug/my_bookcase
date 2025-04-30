import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchFilterState {
  final String searchQuery;
  final bool showStarred;
  final bool showRead;
  final bool showUnread;
  final int? selectedYear;
  final int? selectedMonth;

  SearchFilterState({
    this.searchQuery = '',
    this.showStarred = false,
    this.showRead = false,
    this.showUnread = false,
    this.selectedYear,
    this.selectedMonth,
  });

  SearchFilterState copyWith({
    String? searchQuery,
    bool? showStarred,
    bool? showRead,
    bool? showUnread,
    int? selectedYear,
    int? selectedMonth,
  }) {
    return SearchFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      showStarred: showStarred ?? this.showStarred,
      showRead: showRead ?? this.showRead,
      showUnread: showUnread ?? this.showUnread,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }
}

class SearchFilterNotifier extends StateNotifier<SearchFilterState> {
  SearchFilterNotifier() : super(SearchFilterState());

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    /* SearchFilterState(
      searchQuery: query,
      showStarred: state.showStarred,
      showRead: state.showRead,
      showUnread: state.showUnread,
    ); */
  }

  void toggleShowStarred(bool value) {
    state = state.copyWith(showStarred: value);
  }

  void toggleShowRead(bool value) {
    state = state.copyWith(showRead: value);
  }

  void toggleShowUnread(bool value) {
    state = state.copyWith(showUnread: value);
  }

  void updateYear(int? year) {
    state = state.copyWith(selectedYear: year);
  }

  void updateMonth(int? month) {
    state = state.copyWith(selectedMonth: month);
  }

  void resetFilters() {
    state = SearchFilterState();
  }
}

final searchFilterProvider =
    StateNotifierProvider<SearchFilterNotifier, SearchFilterState>(
  (ref) => SearchFilterNotifier(),
);

final searchControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

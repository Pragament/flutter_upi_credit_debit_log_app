// StateNotifier for search query
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/pay.dart';

final searchControllerProvider = StateNotifierProvider<SearchControllerNotifier, TextEditingController>(
      (ref) => SearchControllerNotifier(),
);

class SearchControllerNotifier extends StateNotifier<TextEditingController> {
  SearchControllerNotifier() : super(TextEditingController());

  void updateText(String text) {
    state.text = text;
  }
}


// StateNotifier for sorting order
class SortOrderNotifier extends StateNotifier<bool> {
  SortOrderNotifier() : super(true); // Default is ascending

  void toggleSortOrder() {
    state = !state;
  }
}

// StateNotifier for archived accounts filter
class ShowArchivedNotifier extends StateNotifier<bool> {
  ShowArchivedNotifier() : super(false);

  void toggleArchived() {
    state = !state;
  }
}

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

// StateNotifier for managing accounts
class AccountsNotifier extends StateNotifier<List<Accounts>> {
  AccountsNotifier() : super([]);

  // Add a method to load accounts, perhaps from a database
  void loadAccounts(List<Accounts> accounts) {
    state = accounts;
  }

// Add other methods for modifying the accounts list if needed
}

// StateNotifier for products
class ProductNotifier extends StateNotifier<List<Product>> {
  ProductNotifier() : super([]);

// Add methods to fetch and update products if needed
}

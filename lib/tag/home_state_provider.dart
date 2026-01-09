import 'package:flutter_template/tag/home_state_model.dart';
import 'package:flutter_template/tag/tag_model.dart';
import 'package:flutter_template/upi/model/pay.dart';
import 'package:flutter_template/upi/provider/account_provider.dart';
import 'package:flutter_template/upi/provider/product_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_state_provider.g.dart';

@riverpod
class HomeStateNotifier extends _$HomeStateNotifier {
  List<Tag> _selectedTags = [];
  
  @override
  HomeStateModel build() {
    // Watch the accounts and products providers
    final accounts = ref.watch(accountsProvider);
    final products = ref.watch(productProvider);
    
    // Apply filtering if tags are selected
    if (_selectedTags.isNotEmpty) {
      return _applyFiltering(accounts, products, _selectedTags);
    }
    
    return HomeStateModel(
      accounts: accounts,
      products: products,
      selectedTags: _selectedTags,
    );
  }

  HomeStateModel _applyFiltering(List<Accounts> accounts, List<Product> products, List<Tag> selectedTags) {
    if (selectedTags.isEmpty) {
      return HomeStateModel(
        accounts: List.from(accounts),
        products: List.from(products),
        selectedTags: selectedTags,
      );
    }

    // Filter accounts based on selected tags - include account if it has any of the selected tags
    // OR if any of its products have any of the selected tags
    List<Accounts> filteredAccounts = accounts.where((account) {
      // Check if account has any of the selected tags
      final accountHasTag = account.tags.any((accountTag) =>
          selectedTags.map((e) => e.id).contains(accountTag.id));
      
      if (accountHasTag) return true;
      
      // Check if any product of this account has any of the selected tags
      return account.productIds.any((productId) {
        final product = products.firstWhere(
          (p) => p.id == productId,
          orElse: () => Product(
            id: -1,
            name: '',
            price: 0.0,
            description: '',
            imageUrl: '',
            tags: [],
          ),
        );
        return product.id != -1 && product.tags.any((productTag) =>
            selectedTags.map((e) => e.id).contains(productTag.id));
      });
    }).toList();

    // Filter products based on selected tags
    List<Product> filteredProducts = products.where((product) {
      // If product has any of the selected tags, include it
      return product.tags.any((productTag) =>
          selectedTags.map((e) => e.id).contains(productTag.id));
    }).toList();

    return HomeStateModel(
      accounts: filteredAccounts,
      products: filteredProducts,
      selectedTags: selectedTags,
    );
  }

  void updateTagSelection(List<Tag> selectedTags) {
    // Update the selected tags
    _selectedTags = selectedTags;
    
    // Get the latest accounts and products by reading providers
    final accounts = ref.read(accountsProvider);
    final products = ref.read(productProvider);
    
    // Apply filtering and update state
    state = _applyFiltering(accounts, products, selectedTags);
  }
}

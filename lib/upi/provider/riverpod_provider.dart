import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quick_actions/quick_actions.dart';

import '../model/pay.dart';
import '../screens/create_order_screen.dart';
import 'notifiers.dart';


/// State provider for managing the selected page index
final selectedPageIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for the PageController
final pageControllerProvider = StateNotifierProvider<PageControllerNotifier, PageController>((ref) {
  return PageControllerNotifier();
});

class PageControllerNotifier extends StateNotifier<PageController> {
  PageControllerNotifier() : super(PageController());

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }
}


final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
      (ref) => GlobalKey<NavigatorState>(),
);

final hiveInitializationProvider = FutureProvider<void>((ref) async {
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  Hive.registerAdapter(OrderAdapter());
  Hive.registerAdapter(AccountsAdapter());
  Hive.registerAdapter(ProductAdapter());

  await Hive.openBox<Order>('orders');
  await Hive.openBox<Accounts>('accounts');
  await Hive.openBox<Product>('products');
});

final hiveBoxOpenProvider = FutureProvider<void>((ref) async {
  await Hive.openBox<Order>('orders');
  await Hive.openBox<Accounts>('accounts');
  await Hive.openBox<Product>('products');
});

final quickActionsProvider = Provider<QuickActions>((ref) {
  final navigatorKey = ref.read(navigatorKeyProvider);
  return QuickActions()
    ..initialize((String shortcutType) {
      if (shortcutType.startsWith('create_order_')) {
        final accountId = int.parse(shortcutType.split('_').last);

        // Fetch the actual account for the given accountId
        final accountsBox = Hive.box<Accounts>('accounts');
        final account = accountsBox.get(accountId);

        if (account != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => CreateOrderScreen(
                account: account,
                onOrderCreated: () => _refresh(ref),
              ),
            ),
          );
        }
      } else if (shortcutType.startsWith('view_product_')) {
        final productId = int.parse(shortcutType.split('_').last);

        // Fetch the product and associated account
        final productsBox = Hive.box<Product>('products');
        final product = productsBox.get(productId);

        final accountsBox = Hive.box<Accounts>('accounts');
        final account = accountsBox.values.firstWhere(
              (s) => s.productIds.contains(productId),
          orElse: () => Accounts(
            id: -1,
            merchantName: '',
            upiId: '',
            color: 0,
            createShortcut: false,
            archived: false,
            productIds: [],
            currency: '',
          ),
        );

        if (product != null && account.id != -1) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => CreateOrderScreen(
                account: account,
                products: [product],
                onOrderCreated: () => _refresh(ref),
              ),
            ),
          );
        }
      }
    });
});

// StateNotifier for managing search query
class SearchQueryNotifier extends StateNotifier<String> {
  SearchQueryNotifier() : super('');

  void updateQuery(String query) {
    state = query; // Update the search query
  }
}
final searchQueryProviders = StateNotifierProvider<SearchQueryNotifier, String>(
      (ref) => SearchQueryNotifier(),
);

// StateNotifier for managing the sorting order
final sortOrderProvider = StateNotifierProvider<SortOrderNotifier, bool>(
      (ref) => SortOrderNotifier(),
);

// StateNotifier for managing the archived accounts filter
final showArchivedProvider = StateNotifierProvider<ShowArchivedNotifier, bool>(
      (ref) => ShowArchivedNotifier(),
);

// StateNotifier for managing the list of products
final productProvider = StateNotifierProvider<ProductNotifier, List<Product>>(
      (ref) => ProductNotifier(),
);


void _refresh(ref) {
  // Implement refresh logic if needed
}

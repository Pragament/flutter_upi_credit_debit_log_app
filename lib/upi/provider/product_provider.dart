import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../model/pay.dart';

// Define a ProductNotifier to manage product state
class ProductNotifier extends StateNotifier<List<Product>> {
  ProductNotifier() : super([]);

  void addProduct(Product product) {
    state = [...state, product];
    final productBox = Hive.box<Product>('products');
    productBox.put(product.id, product);
  }

  void updateProduct(Product updatedProduct) {
    state = state.map((product) => product.id == updatedProduct.id ? updatedProduct : product).toList();
    final productBox = Hive.box<Product>('products');
    productBox.put(updatedProduct.id, updatedProduct);
  }

  Future<void> fetchProducts(List<int> productIds) async {
    var box = Hive.box<Product>('products');
    List<Product> products = [];
    for (int productId in productIds) {
      var product = box.get(productId);
      if (product != null) {
        products.add(product);
      }
    }
    state = products; // Update the state with fetched products
  }

}

// Create a provider for the ProductNotifier
final productProvider = StateNotifierProvider<ProductNotifier, List<Product>>((ref) {
  return ProductNotifier();
});

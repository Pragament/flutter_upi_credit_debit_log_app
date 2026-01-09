import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../model/pay.dart';

// Define a ProductNotifier to manage product state
class ProductNotifier extends StateNotifier<List<Product>> {
  ProductNotifier() : super([]);

  void addProduct(Product product) {
    try {
      final productBox = Hive.box<Product>('products');
      productBox.put(product.id, product);
      state = [...state, product];
      print('Product saved successfully: ${product.name} with ID: ${product.id}');
    } catch (e) {
      print('Error saving product: $e');
    }
  }

  void updateProduct(Product updatedProduct) {
    try {
      final productBox = Hive.box<Product>('products');
      productBox.put(updatedProduct.id, updatedProduct);
      state = state.map((product) => product.id == updatedProduct.id ? updatedProduct : product).toList();
      print('Product updated successfully: ${updatedProduct.name} with ID: ${updatedProduct.id}');
    } catch (e) {
      print('Error updating product: $e');
    }
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

  Future<void> fetchAllProducts() async {
    var box = Hive.box<Product>('products');
    List<Product> products = [];

    // Retrieve all keys from the box and fetch each corresponding product
    final keys = box.keys.cast<int>();
    for (int key in keys) {
      var product = box.get(key);
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

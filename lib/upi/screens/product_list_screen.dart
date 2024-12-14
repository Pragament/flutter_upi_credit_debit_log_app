import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../model/pay.dart';
import 'create_order_screen.dart';

final productBoxProvider = Provider<Box<Product>>((ref) {
  return Hive.box<Product>('products');
});

final refreshNotifierProvider = StateProvider<bool>((ref) => false);

class ProductListScreen extends ConsumerWidget {
  final Accounts accounts;
  final Function(BuildContext, Product, Accounts, Function()) showEditProductForm;

  const ProductListScreen({
    Key? key,
    required this.accounts,
    required this.showEditProductForm,
  }) : super(key: key);

  void _refresh(BuildContext context, WidgetRef ref) {
    ref.read(refreshNotifierProvider.notifier).state = !ref.read(refreshNotifierProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productBox = ref.watch(productBoxProvider);

    // Trigger rebuild when refreshNotifier changes
    ref.watch(refreshNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${accounts.merchantName} Products'),
      ),
      body: accounts.productIds.isNotEmpty
          ? ListView.builder(
        itemCount: accounts.productIds.length,
        itemBuilder: (context, index) {
          final productId = accounts.productIds[index];
          final product = productBox.get(productId);

          return _buildProductTile(
            context,
            product,
            accounts,
            ref,
          );
        },
      )
          : const Center(
        child: Text("No products added"),
      ),
    );
  }

  GestureDetector _buildProductTile(
      BuildContext context,
      Product? product,
      Accounts accounts,
      WidgetRef ref,
      ) {
    return GestureDetector(
      onTap: () {
        if (product != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateOrderScreen(
                account: accounts,
                products: [product],
                onOrderCreated: () => _refresh(context, ref),
              ),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.name ?? 'Unknown Product',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    product != null
                        ? '₹${product.price.toStringAsFixed(2)}'
                        : 'Price not available',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    product?.description ?? 'No description available',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            if (product != null && product.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: product.imageUrl.startsWith('http')
                    ? Image.network(
                  product.imageUrl,
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                )
                    : Image.file(
                  File(product.imageUrl),
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Icon(Icons.image_not_supported, color: Colors.grey, size: 60),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              onPressed: () {
                if (product != null) {
                  showEditProductForm(
                    context,
                    product,
                    accounts,
                        () => _refresh(context, ref),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

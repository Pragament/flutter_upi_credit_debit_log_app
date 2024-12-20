import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:table_calendar/table_calendar.dart';

import '../model/pay.dart';
import 'order_details_screen.dart';

final selectedStatusProvider = StateProvider<String>((ref) => 'all');
final searchQueryProvider = StateProvider<String>((ref) => '');
final dateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final ordersBoxProvider = FutureProvider<Box<Order>>((ref) async {
  return await Hive.openBox<Order>('orders');
});

final productsBoxProvider = FutureProvider<Box<Product>>((ref) async {
  return await Hive.openBox<Product>('products');
});

class TransactionScreen extends ConsumerWidget {
  final Accounts? account;

  const TransactionScreen({super.key, this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(selectedStatusProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final dateRange = ref.watch(dateRangeProvider);

    final ordersBoxAsync = ref.watch(ordersBoxProvider);
    final productsBoxAsync = ref.watch(productsBoxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Transactions'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) =>
              ref.read(searchQueryProvider.notifier).state = value.toLowerCase(),
              decoration: const InputDecoration(
                hintText: 'Search by product...',
                hintStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Filter Options
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: selectedStatus,
                  items: const ['all', 'pending', 'completed'].map((value) {
                    return DropdownMenuItem(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) =>
                  ref.read(selectedStatusProvider.notifier).state = newValue ?? 'all',
                  icon: const Icon(Icons.filter_list),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () => _showDateRangePicker(context, ref),
                ),
                if (dateRange != null)
                  Row(
                    children: [
                      Text(
                        '${DateFormat('d MMM, yy').format(dateRange.start)} - '
                            '${DateFormat('d MMM, yy').format(dateRange.end)}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => ref.read(dateRangeProvider.notifier).state = null,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Transactions List
          Expanded(
            child: ordersBoxAsync.when(
              data: (ordersBox) {
                final productBox = ref.watch(productsBoxProvider).asData?.value;
                if (productBox == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = ordersBox.values.where((order) {
                  final matchesStatus =
                      selectedStatus == 'all' || order.status == selectedStatus;

                  final matchesAccount = account == null ||
                      order.products.keys.any((productId) =>
                          account!.productIds.contains(productId));

                  final matchesSearch = searchQuery.isEmpty ||
                      order.products.keys.any((productId) {
                        final product = productBox.get(productId);
                        return product != null &&
                            product.name.toLowerCase().contains(searchQuery);
                      });

                  final matchesDate = dateRange == null ||
                      (order.timestamp.isAfter(dateRange.start) &&
                          order.timestamp.isBefore(dateRange.end));

                  return matchesStatus && matchesAccount && matchesSearch && matchesDate;
                }).toList();

                if (orders.isEmpty) {
                  return const Center(child: Text('No transactions available.'));
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(order: order);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text(error.toString())),
            ),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker(BuildContext context, WidgetRef ref) {
    final dateRange = ref.read(dateRangeProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        DateTime? tempStart = dateRange?.start;
        DateTime? tempEnd = dateRange?.end;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TableCalendar(
                    focusedDay: DateTime.now(),
                    firstDay: DateTime(2000),
                    lastDay: DateTime(2100),
                    rangeSelectionMode: RangeSelectionMode.toggledOn,
                    rangeStartDay: tempStart,
                    rangeEndDay: tempEnd,
                    onRangeSelected: (start, end, _) {
                      setModalState(() {
                        tempStart = start;
                        tempEnd = end;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (tempStart != null && tempEnd != null) {
                        ref.read(dateRangeProvider.notifier).state =
                            DateTimeRange(start: tempStart!, end: tempEnd!);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Date Filter'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedTimestamp =
    DateFormat('d MMMM yyyy, h:mma').format(order.timestamp);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(order: order),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ProductImagesList(
                        productIds: order.products.keys.toList()),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _showEditDialog(context, order);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Order ${order.status}',
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Placed at: $formattedTimestamp',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        const WidgetSpan(
                          child: Icon(Icons.currency_rupee, size: 16),
                        ),
                        TextSpan(
                          text: ' ${order.amount}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Order order) {
    final amountController = TextEditingController(text: order.amount);
    String? selectedStatus = order.status;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: <String>['pending', 'completed'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  selectedStatus = newValue;
                },
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (selectedStatus != null) {
                  order.status = selectedStatus!;
                  order.amount = amountController.text;
                  order.save();
                }

                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class ProductImagesList extends StatelessWidget {
  final List<int> productIds;

  const ProductImagesList({Key? key, required this.productIds})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productBox = Hive.box<Product>('products');
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productIds.length,
        itemBuilder: (context, index) {
          final product = productBox.get(productIds[index]);

          return product != null
              ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.file(
                  File(product.imageUrl),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
                Text(
                  product.name,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          )
              : const SizedBox();
        },
      ),
    );
  }
}
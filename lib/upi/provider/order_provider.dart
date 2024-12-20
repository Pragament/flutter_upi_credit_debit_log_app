import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../model/pay.dart';

class OrderNotifier extends StateNotifier<List<Order>> {
  OrderNotifier() : super([]);

  void addOrder(Order order) {
    state = [...state, order];
    final orderBox = Hive.box<Order>('orders');
    orderBox.add(order);
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, List<Order>>((ref) => OrderNotifier());
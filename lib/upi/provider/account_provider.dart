// accounts_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../model/pay.dart';



final accountsProvider = StateNotifierProvider<AccountsNotifier, List<Accounts>>(
      (ref) => AccountsNotifier(),
);

class AccountsNotifier extends StateNotifier<List<Accounts>> {
  AccountsNotifier() : super([]) {
    fetchAccounts(); // Fetch accounts on initialization
  }

  void fetchAccounts() {
    final accountsList = Hive.box<Accounts>('accounts').values.toList();
    state = accountsList;
  }

  Future<void> addAccount(Accounts account) async {
    await Hive.box<Accounts>('accounts').put(account.id, account);
    fetchAccounts(); // Refresh the list after adding
  }

  Future<void> updateAccount(Accounts account) async {
    await account.save();
    fetchAccounts(); // Refresh the list after updating
  }

  Future<void> deleteAccount(Accounts account) async {
    await account.delete();
    fetchAccounts(); // Refresh the list after deletion
  }

  Future<void> addProductIdToAccount(int accountKey, int productId) async {
    final accountBox = Hive.box<Accounts>('accounts');
    final account = accountBox.get(accountKey);

    if (account != null) {
      account.productIds.add(productId);
      await account.save();
      fetchAccounts(); // Call fetchAccounts() to notify the state
    }
  }

}


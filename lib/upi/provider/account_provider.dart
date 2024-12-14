// accounts_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../model/pay.dart';



final accountsProvider = StateNotifierProvider<AccountsNotifier, List<Accounts>>(
      (ref) => AccountsNotifier(),
);

class AccountsNotifier extends StateNotifier<List<Accounts>> {
  AccountsNotifier() : super([]);

  // Initialize the list by fetching all accounts from Hive
  void fetchAccounts() {
    final accountsList = Hive.box<Accounts>('accounts').values.toList();
    state = accountsList;
  }

  // Add a new account
  Future<void> addAccount(Accounts account) async {
    await Hive.box<Accounts>('accounts').put(account.id, account);
    fetchAccounts();  // Refresh the list after adding
  }

  // Update an existing account
  Future<void> updateAccount(Accounts account) async {
    await account.save();
    fetchAccounts();  // Refresh the list after updating
  }

  // Delete an account
  Future<void> deleteAccount(Accounts account) async {
    await account.delete();
    fetchAccounts();  // Refresh the list after deletion
  }
}

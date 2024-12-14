import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/upi/screens/transaction_screen.dart';
import 'package:flutter_template/upi/screens/widgets/custom_appbar.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:quick_actions/quick_actions.dart';

import '../model/pay.dart';
import '../provider/account_provider.dart';
import '../provider/form_data.dart';
import '../provider/notifiers.dart';
import '../provider/riverpod_provider.dart';
import '../utils/utils.dart';
import 'create_order_screen.dart';

final accountsBox = Hive.box<Accounts>('accounts');
final productBox = Hive.box<Product>('products');

class HomeScreen1 extends ConsumerWidget {
  final QuickActions quickActions;

  const HomeScreen1({super.key, required this.quickActions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = ref.watch(searchControllerProvider);
    final accountsList = ref.watch(accountsProvider);

    return Scaffold(
      appBar: customAppBar(ref, searchController),
      floatingActionButton: _buildFloatingActionButton(ref),
      body: customBody(ref, accountsList),
    );
  }


  List<Accounts> filterAccounts(List<Accounts> accountsList, String query) {
    if (query.isEmpty) return accountsList;

    return accountsList.where((account) {
      // Check if the account name or UPI ID matches the search query
      final accountMatches =
          account.merchantName.toLowerCase().contains(query.toLowerCase()) ||
              account.upiId.toLowerCase().contains(query.toLowerCase());

      // Check if any product associated with this account matches the search query
      final productMatches = account.productIds.any((productId) {
        final product = productBox.get(productId);
        return product != null &&
            (product.name.toLowerCase().contains(query.toLowerCase()) ||
                product.description
                    .toLowerCase()
                    .contains(query.toLowerCase()));
      });

      return accountMatches || productMatches;
    }).toList();
  }


  Widget customBody(WidgetRef ref, List<Accounts> accountsList) {
    final isAscending = ref.watch(sortOrderProvider);
    final showArchived = ref.watch(showArchivedProvider);
    final searchQuery = ref.watch(searchQueryProviders);

    // Fetch and filter accounts
    accountsList.sort((a, b) {
      int compareResult = a.merchantName
          .toLowerCase()
          .compareTo(b.merchantName.toLowerCase());
      return isAscending ? compareResult : -compareResult;
    });

    final filteredAccounts = filterAccounts(accountsList, searchQuery).where((account) {
      if (showArchived) {
        return account.archived;
      } else {
        return !account.archived;
      }
    }).toList();

    return ListView.builder(
      itemCount: filteredAccounts.length,
      itemBuilder: (context, index) {
        final account = filteredAccounts[index];
        final initials = getInitials(account.merchantName);

        // Filtered products
        final filteredProducts = account.productIds.map((productId) {
          return productBox.get(productId);
        }).where((product) {
          if (searchQuery.isEmpty) return true;
          return product != null &&
              (product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  product.description.toLowerCase().contains(searchQuery.toLowerCase()));
        }).toList();

        final shouldDisplayAllProducts = account.merchantName
            .toLowerCase()
            .contains(searchQuery.toLowerCase()) ||
            account.upiId.toLowerCase().contains(searchQuery.toLowerCase());

        return itemCard(
          context,
          account,
          initials,
          shouldDisplayAllProducts
              ? account.productIds.map((id) => productBox.get(id)).whereType<Product>().toList()
              : filteredProducts,
          ref,
        );
      },
    );
  }

  void refresh() {
    // setState(() {});
  }
  Container itemCard(BuildContext context, Accounts accounts, String initials,
      List<Product?> filteredProducts, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 2,
            child: ListTile(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateOrderScreen(
                      account: accounts,
                      onOrderCreated: refresh,
                    ),
                  ),
                );
              },
              contentPadding: const EdgeInsets.all(16.0),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(accounts.color),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              title: Text(accounts.merchantName),
              subtitle: Text(formatUpiId(accounts.upiId)),
              trailing: SizedBox(
                width: 96, // Adjust the width as needed
                child: Row(
                  mainAxisSize: MainAxisSize
                      .min, // Ensures the row does not take up more space than necessary
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionScreen(
                              account: accounts,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showForm(accounts: accounts, ref: ref),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Row(
          //   children: [
          //     IconButton(
          //       icon: const Icon(Icons.add),
          //       onPressed: () => _showAddProductForm(context, accounts),
          //       padding: const EdgeInsets.all(8.0),
          //     ),
          //     IconButton(
          //       icon: const Icon(Icons.import_export),
          //       onPressed: () => _importProductForm(
          //           accounts), // Use a closure to pass the function reference
          //       padding: const EdgeInsets.all(8.0),
          //     ),
          //     IconButton(
          //       icon: const Icon(Icons.arrow_forward),
          //       onPressed: () {
          //         Navigator.of(context).push(
          //           MaterialPageRoute(
          //             builder: (context) => ProductListScreen(
          //               accounts: accounts,
          //               // productBox: productBox,
          //               showEditProductForm: _showEditProductForm,
          //               // refreshHomeScreen: _refresh,
          //             ),
          //           ),
          //         );
          //       },
          //       padding: const EdgeInsets.all(8.0),
          //     ),
          //   ],
          // ),
          SizedBox(
            height: filteredProducts.isNotEmpty ? 110 : 0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];

                return productTile(product, accounts, ref, () {
                  // setState(() {});
                });
              },
            ),
          ),
        ],
      ),
    );
  }
  GestureDetector productTile(Product? product, Accounts accounts, ref, Function() refreshCallback) {
    return GestureDetector(
      onTap: () {
        if (product != null) {
          Navigator.of(ref.context).push(
            MaterialPageRoute(
              builder: (context) => CreateOrderScreen(
                account: accounts, products: [product],
                onOrderCreated: refresh,
                // Passing the product price as the amount
              ),
            ),
          );
        }
      },
      child: Container(
        width: 220,
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product != null && product.name.isNotEmpty
                              ? product.name
                              : 'Unknown Product',
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              overflow: TextOverflow.ellipsis),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          product != null
                              ? '₹${product.price.toString()}'
                              : 'Price not available',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          product != null && product.description.isNotEmpty
                              ? product.description
                              : 'No description available',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14.0,
                          ),
                          textAlign: TextAlign.left,
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
                          ? SizedBox()
                      // Image.network(
                      //     product.imageUrl,
                      //     height: 0,
                      //     width: 0,
                      //     fit: BoxFit.cover,
                      //   )
                          : Image.file(
                        File(product.imageUrl),
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    const Icon(Icons.category, color: Colors.grey, size: 100),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: Colors.black,
                  size: 30,
                ),
                onPressed: () {
                  if (product != null) {
                    // _showEditProductForm(
                    //     context, product, accounts, refreshCallback);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  FloatingActionButton _buildFloatingActionButton(WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showForm(ref: ref),
      child: const Icon(Icons.add),
    );
  }

  Future<bool> _authenticate() async {
    return true;
    final LocalAuthentication auth = LocalAuthentication();
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isAuthenticated = false;

      if (canCheckBiometrics) {
        isAuthenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to access the app',
          options: const AuthenticationOptions(biometricOnly: true),
        );
      } else {}

      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  void _showForm({Accounts? accounts, required WidgetRef ref}) {
    if (accounts != null) {
      ref.read(formDataProvider.notifier).updateMerchantName(accounts.merchantName);
      ref.read(formDataProvider.notifier).updateUpiId(accounts.upiId);
      ref.read(formDataProvider.notifier).updateCurrency(accounts.currency);
      ref.read(formDataProvider.notifier).updateSelectedColor(Color(accounts.color)); // Convert int to Color
      if (accounts.createShortcut != ref.watch(formDataProvider).createShortcut) {
        ref.read(formDataProvider.notifier).toggleCreateShortcut();
      }
    } else {
      ref.read(formDataProvider.notifier).reset();
    }

    final bool isArchived = accounts?.archived ?? false;
    final DateTime? archiveDate = accounts?.archiveDate;
    final bool isDeletable = !isArchived ||
        (archiveDate != null && DateTime.now().difference(archiveDate).inDays >= 30);

    showDialog(
      context: ref.context,
      builder: (_) => FutureBuilder<bool>(
        future: _authenticate(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError || !snapshot.data!) {
            return const Scaffold(
              body: Center(child: Text('Authentication failed')),
            );
          } else {
            return dialog(accounts, isDeletable, ref);
          }
        },
      ),
    );
  }

  Consumer dialog(Accounts? accounts, bool isDeletable, WidgetRef ref) {
    // Declare controllers outside the rebuild logic to make them persistent
    final merchantNameController = TextEditingController();
    final upiIdController = TextEditingController();

    return Consumer(
      builder: (context, watchRef, child) {
        final formData = watchRef.watch(formDataProvider);

        // Synchronize controller text with formData
        merchantNameController.text = formData.merchantName;
        merchantNameController.selection = TextSelection.fromPosition(
          TextPosition(offset: merchantNameController.text.length),
        );

        upiIdController.text = formData.upiId;
        upiIdController.selection = TextSelection.fromPosition(
          TextPosition(offset: upiIdController.text.length),
        );

        return AlertDialog(
          title: Text(accounts == null ? 'Add Account' : 'Edit Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: merchantNameController,
                  decoration: const InputDecoration(labelText: 'Merchant Name'),
                  onChanged: (value) => ref.read(formDataProvider.notifier).updateMerchantName(value),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: upiIdController,
                  decoration: const InputDecoration(labelText: 'UPI ID'),
                  onChanged: (value) => ref.read(formDataProvider.notifier).updateUpiId(value),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: Text('Currency:', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    DropdownButton<String>(
                      value: formData.currency,
                      items: ['INR'].map((String currency) {
                        return DropdownMenuItem<String>(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          ref.read(formDataProvider.notifier).updateCurrency(newValue);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    const Text('Choose Color:'),
                    const SizedBox(width: 8.0),
                    GestureDetector(
                      onTap: () async {
                        final color = await showDialog<Color>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Pick a color'),
                            content: SingleChildScrollView(
                              child: BlockPicker(
                                pickerColor: formData.selectedColor,
                                onColorChanged: (color) {
                                  ref.read(formDataProvider.notifier).updateSelectedColor(color);
                                  Navigator.of(context).pop(color);
                                },
                              ),
                            ),
                          ),
                        );
                        if (color != null) {
                          ref.read(formDataProvider.notifier).updateSelectedColor(color);
                        }
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        color: formData.selectedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Checkbox(
                      value: formData.createShortcut,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(formDataProvider.notifier).toggleCreateShortcut();
                        }
                      },
                    ),
                    const Text('Create Shortcut'),
                  ],
                ),
                if (accounts != null) ...[
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Checkbox(
                        value: accounts.archived,
                        onChanged: (value) {
                          if (value != null) {
                            accounts.archived = value;
                            accounts.archiveDate = value ? DateTime.now() : null;
                          }
                        },
                      ),
                      const Text('Archived'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (accounts != null)
              TextButton(
                onPressed: () {
                  if (!isDeletable) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'You cannot delete this account until 30 days have passed since archiving.'),
                    ));
                  } else {
                    _deleteAccounts(accounts, ref);
                  }
                  Navigator.of(context).pop();
                },
                child: Text('Delete', style: TextStyle(color: isDeletable ? Colors.red : Colors.grey)),
              ),
            TextButton(
              onPressed: () {
                if (accounts == null) {
                  _addAccounts(ref);
                } else {
                  // Call your update function here
                  _updateAccounts(accounts, ref);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addAccounts(ref) async {
    final formData = ref.watch(formDataProvider);
    final id = accountsBox.isEmpty ? 0 : accountsBox.values.last.id + 1;
    final accounts = Accounts(
      id: id,
      merchantName: formData.merchantName,
      upiId: formData.upiId,
      currency: formData.currency,
      color: formData.selectedColor.value,
      createShortcut: formData.createShortcut,
      archived: false,
      productIds: [],
    );
    await ref.read(accountsProvider.notifier).addAccount(accounts); // Use the provider to add
    _manageQuickActions();

    // await accountsBox.put(id, accounts);
    if (formData.createShortcut) {
      _createQuickAction(accounts);
    }
    // print("Account added succesfully: ");
    // _manageQuickActions(); // Refresh the quick actions
    // await ref.read(accountsProvider.notifier);
  }

  void _createQuickAction(Accounts accounts) {
    quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(
        type: 'create_order_${accounts.id}',
        localizedTitle: 'Create Order for ${accounts.merchantName}',
        //icon: 'icon_add_order',
      ),
    ]);
  }

  Future<void> _updateAccounts(Accounts account, ref) async{
    final formData = ref.watch(formDataProvider);
    account.merchantName = formData.merchantName;
    account.upiId = formData.upiId;
    account.currency = formData.currency;
    account.color = formData.selectedColor.value;
    account.createShortcut = formData.createShortcut;

    if (account.archived == false) {
      account.archiveDate = null;
    } else if (account.archived) {
      account.archiveDate = DateTime.now();
    }

    await ref.read(accountsProvider.notifier).updateAccount(account);
    _manageQuickActions();
    await ref.read(accountsProvider.notifier);
  }

  void _manageQuickActions() {
    // Fetch quick actions for accounts
    final accountShortcuts = Hive.box<Accounts>('accounts')
        .values
        .where((accounts) => accounts.createShortcut)
        .map((accounts) {
      return ShortcutItem(
        type: 'create_order_${accounts.id}',
        localizedTitle: 'Create Order for ${accounts.merchantName}',
      );
    }).toList();

    // Fetch quick actions for products
    final productShortcuts =
    Hive.box<Product>('products').values.map((product) {
      return ShortcutItem(
        type: 'view_product_${product.id}',
        localizedTitle: 'View Product ${product.name}',
      );
    }).toList();

    // Combine both lists of shortcuts
    final combinedShortcuts = [...accountShortcuts, ...productShortcuts];

    // Set all shortcuts at once
    quickActions.setShortcutItems(combinedShortcuts);
  }

  Future<void> _deleteAccounts(Accounts accounts, ref) async {
    await ref.read(accountsProvider.notifier).deleteAccount(accounts);
    _manageQuickActions(); // Refresh the quick actions
    // await ref.read(accountsProvider.notifier);
  }

}

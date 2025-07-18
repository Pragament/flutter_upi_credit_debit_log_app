import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/upi/screens/product_list_screen.dart';
import 'package:flutter_template/upi/screens/transaction_screen.dart';
import 'package:flutter_template/upi/screens/widgets/custom_appbar.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:quick_actions/quick_actions.dart';

import '../model/pay.dart';
import '../provider/account_provider.dart';
import '../provider/form_data.dart';
import '../provider/notifiers.dart';
import '../provider/product_provider.dart';
import '../provider/riverpod_provider.dart';
import '../utils/utils.dart';
import 'create_order_screen.dart';

import 'dart:async';

import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

final accountsBox = Hive.box<Accounts>('accounts');
final productBox = Hive.box<Product>('products');

class HomeScreen extends ConsumerWidget {
  final QuickActions quickActions;

  const HomeScreen({super.key, required this.quickActions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = ref.watch(searchControllerProvider);
    final accountsList = ref.watch(accountsProvider);
    final productsList = ref.watch(productProvider);

    return Scaffold(
      appBar: customAppBar(ref, searchController),
      floatingActionButton: _buildFloatingActionButton(ref),
      body: accountsList.isEmpty
          ? Center(child: Text('No accounts available'))
          : customBody(ref, accountsList, productsList),
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

  Widget customBody(
      WidgetRef ref, List<Accounts> accountsList, List<Product> productsList) {
    final isAscending = ref.watch(sortOrderProvider);
    final showArchived = ref.watch(showArchivedProvider);
    final searchQuery = ref.watch(searchQueryProviders);

    // Fetch and filter accounts
    accountsList.sort((a, b) {
      int compareResult =
          a.merchantName.toLowerCase().compareTo(b.merchantName.toLowerCase());
      return isAscending ? compareResult : -compareResult;
    });

    final filteredAccounts =
        filterAccounts(accountsList, searchQuery).where((account) {
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

        final filteredProducts = account.productIds
            .map((productId) {
              return productsList.firstWhere(
                (product) => product.id == productId,
                orElse: () => Product(
                    id: -1,
                    name: 'Unknown',
                    price: 0.0,
                    description: '',
                    imageUrl: ''), // Provide a default Product
              );
            })
            .where((product) => product.id != -1)
            .toList(); // Filter out the default Product

        final shouldDisplayAllProducts = account.merchantName
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            account.upiId.toLowerCase().contains(searchQuery.toLowerCase());

        return itemCard(
          context,
          account,
          initials,
          shouldDisplayAllProducts
              ? account.productIds
                  .map((id) => productBox.get(id))
                  .whereType<Product>()
                  .toList()
              : filteredProducts,
          ref,
        );
      },
    );
  }

  void refresh() {}

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
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddProductForm(context, accounts, ref),
                padding: const EdgeInsets.all(8.0),
              ),
              IconButton(
                icon: const Icon(Icons.import_export),
                onPressed: () => _importProductForm(accounts,
                    ref.context), // Use a closure to pass the function reference
                padding: const EdgeInsets.all(8.0),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductListScreen(
                        accounts: accounts,
                        // productBox: productBox,
                        showEditProductForm: _showEditProductForm,
                        // refreshHomeScreen: _refresh,
                      ),
                    ),
                  );
                },
                padding: const EdgeInsets.all(8.0),
              ),
            ],
          ),
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

  _showEditProductForm(BuildContext context, Product product, Accounts accounts,
      WidgetRef ref, Function() refreshCallback) {
    final TextEditingController productNameController =
        TextEditingController(text: product.name);
    final TextEditingController productDescriptionController =
        TextEditingController(text: product.description);
    final TextEditingController productPriceController =
        TextEditingController(text: product.price.toString());

    File? pickedImageFile;
    bool createProdShortcut = product.createShortcut;
    bool isArchived = product.archived;
    DateTime? archiveDate = product.archiveDate;

    final bool isDeletable = !isArchived ||
        (archiveDate != null &&
            DateTime.now().difference(archiveDate).inDays >= 30);

    Future<void> pickImage(StateSetter setState) async {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // Update the state using the setState from StatefulBuilder
        setState(() {
          pickedImageFile = File(pickedFile.path);
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return FutureBuilder<bool>(
              future: _authenticate(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.data!) {
                  return const Center(child: Text('Authentication failed'));
                } else {
                  return editproddialog(
                      productNameController,
                      productDescriptionController,
                      productPriceController,
                      pickImage,
                      setState,
                      pickedImageFile,
                      product,
                      createProdShortcut,
                      isArchived,
                      archiveDate,
                      refreshCallback,
                      context,
                      isDeletable,
                      accounts,
                      ref);
                }
              },
            );
          },
        );
      },
    );
  }

  AlertDialog editproddialog(
      TextEditingController productNameController,
      TextEditingController productDescriptionController,
      TextEditingController productPriceController,
      Future<void> pickImage(StateSetter setState),
      StateSetter setState,
      File? pickedImageFile,
      Product product,
      bool createProdShortcut,
      bool isArchived,
      DateTime? archiveDate,
      refreshCallback(),
      BuildContext context,
      bool isDeletable,
      Accounts accounts,
      ref) {
    return AlertDialog(
      title: const Text('Edit Product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productNameController,
              decoration: const InputDecoration(hintText: 'Enter product name'),
              autofocus: true,
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: productDescriptionController,
              decoration:
                  const InputDecoration(hintText: 'Enter product description'),
              maxLines: 3,
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: productPriceController,
              decoration:
                  const InputDecoration(hintText: 'Enter product price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8.0),
            GestureDetector(
              onTap: () => pickImage(setState),
              child: pickedImageFile != null
                  ? Image.file(
                      pickedImageFile!,
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                    )
                  : product.imageUrl.isNotEmpty
                      ? Image.file(
                          File(product.imageUrl),
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 50,
                          width: 50,
                          color: Colors.grey[300],
                          child: const Icon(Icons.add_a_photo,
                              color: Colors.white),
                        ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Checkbox(
                  value: createProdShortcut,
                  onChanged: (value) {
                    setState(() {
                      createProdShortcut = value!;
                    });
                  },
                ),
                const Text('Create Shortcut'),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Checkbox(
                  value: isArchived,
                  onChanged: (value) {
                    setState(() {
                      isArchived = value!;
                      archiveDate = value ? DateTime.now() : null;
                    });
                  },
                ),
                const Text('Archived'),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            final productName = productNameController.text.trim();
            final productDescription = productDescriptionController.text.trim();
            final productPrice =
                double.tryParse(productPriceController.text.trim()) ?? 0.0;

            if (productName.isNotEmpty) {
              // Update the product details
              final updatedProduct = Product(
                id: product.id,
                name: productName,
                description: productDescription,
                price: productPrice,
                imageUrl: pickedImageFile?.path ?? '',
                archived: isArchived,
                archiveDate: archiveDate,
                createShortcut: createProdShortcut,
              );
              // Use Riverpod to update the Product
              ref.read(productProvider.notifier).updateProduct(updatedProduct);

              // Manage the product shortcut creation
              if (createProdShortcut) {
                product.createShortcut = true;
                _createProductQuickAction(product);
                //_manageProductQuickActions();
                _manageQuickActions();
              } else {
                product.createShortcut = false;
                // _manageProductQuickActions();
                _manageQuickActions();
              }
              final productBox = Hive.box<Product>('products');
              productBox.put(updatedProduct.id, updatedProduct);

              refreshCallback(); // Trigger the refresh in the parent widget
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
        TextButton(
          onPressed: () {
            if (!isDeletable) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'You cannot delete this account until 30 days have passed since archiving.'),
                ),
              );
            } else {
              _deleteproducts(product, accounts);
            }
            refresh();
            Navigator.of(context).pop();
          },
          child: Text(
            'Delete',
            style: TextStyle(
              color: isDeletable ? Colors.red : Colors.grey,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _createProductQuickAction(Product product) {
    const QuickActions quickActions = QuickActions();
    quickActions.setShortcutItems([
      ShortcutItem(
        type: 'view_product_${product.id}',
        localizedTitle: 'View Product ${product.name}',
      ),
    ]);
  }

  Future<void> _deleteproducts(Product product, Accounts account) async {
    await product.delete();

    // Update the accounts product list to remove the deleted product ID
    account.productIds.remove(product.id);
    await account.save(); // Save the updated account object

    //_manageProductQuickActions(); // Refresh the quick actions
    _manageQuickActions();
    // setState(() {});
  }

  void _showAddProductForm(BuildContext context, Accounts accounts, ref) {
    final TextEditingController productNameController = TextEditingController();
    final TextEditingController productDescriptionController =
        TextEditingController();
    final TextEditingController productPriceController =
        TextEditingController();

    File? pickedImageFile;

    Future<void> pickImage(StateSetter setState) async {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // Use setState from StatefulBuilder to update the image
        setState(() {
          pickedImageFile = File(pickedFile.path);
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return FutureBuilder<bool>(
              future: _authenticate(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.data!) {
                  return const Center(child: Text('Authentication failed'));
                } else {
                  return addprodform(
                      productNameController,
                      productDescriptionController,
                      productPriceController,
                      pickImage,
                      setState,
                      pickedImageFile,
                      accounts,
                      context,
                      ref);
                }
              },
            );
          },
        );
      },
    );
  }

  AlertDialog addprodform(
      TextEditingController productNameController,
      TextEditingController productDescriptionController,
      TextEditingController productPriceController,
      Future<void> pickImage(StateSetter setState),
      StateSetter setState,
      File? pickedImageFile,
      Accounts accounts,
      BuildContext context,
      ref) {
    return AlertDialog(
      title: const Text('Add New Product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productNameController,
              decoration: const InputDecoration(hintText: 'Enter product name'),
              autofocus: true,
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: productDescriptionController,
              decoration:
                  const InputDecoration(hintText: 'Enter product description'),
              maxLines: 3,
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: productPriceController,
              decoration:
                  const InputDecoration(hintText: 'Enter product price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8.0),
            GestureDetector(
              onTap: () => pickImage(setState),
              child: pickedImageFile != null
                  ? Image.file(
                      pickedImageFile!,
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 50,
                      width: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.add_a_photo, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            final productName = productNameController.text.trim();
            final productDescription = productDescriptionController.text.trim();
            final productPrice =
                double.tryParse(productPriceController.text.trim()) ?? 0.0;

            if (productName.isNotEmpty) {
              // Generate a unique ID by using the next available integer key
              final productBox = Hive.box<Product>('products');
              final int newProductId =
                  productBox.isEmpty ? 0 : productBox.keys.cast<int>().last + 1;

              // Create the new product
              final newProduct = Product(
                id: newProductId,
                name: productName,
                price: productPrice,
                description: productDescription,
                imageUrl: pickedImageFile!
                    .path, // Store the file path if an image is picked
              );

              // Save the product to the Hive box
              ref.read(productProvider.notifier).addProduct(
                  newProduct); // Use the provider to add the product
              accounts.productIds.add(newProductId);
              Hive.box<Accounts>('accounts').put(accounts.key, accounts);
              Navigator.of(context).pop();
            }
            refresh();
          },
          child: const Text('Save'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  GestureDetector productTile(
      Product? product, Accounts accounts, ref, Function() refreshCallback) {
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
                    _showEditProductForm(
                        ref.context, product, accounts, ref, refreshCallback);
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
    final LocalAuthentication auth = LocalAuthentication();
    return true;
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
      ref
          .read(formDataProvider.notifier)
          .updateMerchantName(accounts.merchantName);
      ref.read(formDataProvider.notifier).updateUpiId(accounts.upiId);
      ref.read(formDataProvider.notifier).updateCurrency(accounts.currency);
      ref
          .read(formDataProvider.notifier)
          .updateSelectedColor(Color(accounts.color)); // Convert int to Color
      if (accounts.createShortcut !=
          ref.watch(formDataProvider).createShortcut) {
        ref.read(formDataProvider.notifier).toggleCreateShortcut();
      }
    } else {
      ref.read(formDataProvider.notifier).reset();
    }

    final bool isArchived = accounts?.archived ?? false;
    final DateTime? archiveDate = accounts?.archiveDate;
    final bool isDeletable = !isArchived ||
        (archiveDate != null &&
            DateTime.now().difference(archiveDate).inDays >= 30);

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

  Future<Map<String, String?>?> _scanQRCode(BuildContext context) async {
    final qrKey = GlobalKey(debugLabel: 'QR'); // Key for QR scanner
    final Completer<String?> qrCompleter = Completer();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Scan QR Code"),
        content: SizedBox(
          width: 300,
          height: 300,
          child: QRView(
            key: qrKey,
            onQRViewCreated: (QRViewController controller) {
              controller.scannedDataStream.listen((scanData) {
                if (!qrCompleter.isCompleted) {
                  qrCompleter.complete(scanData.code);
                  Navigator.of(context).pop(); // Close scanner dialog
                }
              });
            },
          ),
        ),
      ),
    );

    String? qrData = await qrCompleter.future;

    if (qrData != null) {
      Uri uri = Uri.parse(qrData);
      String? upiId = uri.queryParameters["pa"];
      String? merchantName = uri.queryParameters["pn"];

      return {"upiId": upiId, "merchantName": merchantName};
    }

    return null;
  }

  Future<Map<String, String?>?> _pickQRCodeImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return null;

    File imageFile = File(pickedFile.path);

    // Extract QR Code data from image
    String? qrData = await _extractQRCode(imageFile);

    if (qrData != null) {
      Uri uri = Uri.parse(qrData);
      String? upiId = uri.queryParameters["pa"];
      String? merchantName = uri.queryParameters["pn"];

      return {"upiId": upiId, "merchantName": merchantName};
    }

    return null;
  }

// Replace this with an actual QR code decoding implementation
  Future<String?> _extractQRCode(File imageFile) async {
    // Use a QR Code scanner package like 'google_ml_kit' or 'qr_code_dart'
    return "upi://pay?pa=test@upi&pn=Test Merchant"; // Simulated UPI QR Data
  }

  Consumer dialog(Accounts? accounts, bool isDeletable, WidgetRef ref) {
    // Declare controllers outside the rebuild logic to make them persistent
    final archivedNotifier = StateProvider<bool>((ref) => false);
    final merchantNameController = TextEditingController();
    final upiIdController = TextEditingController();

    return Consumer(
      builder: (context, watchRef, child) {
        final formData = watchRef.watch(formDataProvider);

        // Synchronize controller text with formData
        merchantNameController.text = formData.merchantName;
        upiIdController.text = formData.upiId;

        return AlertDialog(
          title: Text(accounts == null ? 'Add Account' : 'Edit Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: merchantNameController,
                  decoration: const InputDecoration(labelText: 'Merchant Name'),
                  onChanged: (value) => ref
                      .read(formDataProvider.notifier)
                      .updateMerchantName(value),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: upiIdController,
                  decoration: const InputDecoration(labelText: 'UPI ID'),
                  onChanged: (value) =>
                      ref.read(formDataProvider.notifier).updateUpiId(value),
                ),
                const SizedBox(height: 16.0),

                // QR Code Scanner & Image Picker Buttons
                SizedBox(
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text("Scan QR"),
                          onPressed: () async {
                            Map<String, String?>? qrDetails =
                                await _scanQRCode(context);

                            if (qrDetails != null) {
                              String? upiId = qrDetails["upiId"];
                              String? merchantName = qrDetails["merchantName"];

                              if (upiId != null) {
                                ref
                                    .read(formDataProvider.notifier)
                                    .updateUpiId(upiId);
                                upiIdController.text = upiId;
                              }

                              if (merchantName != null) {
                                ref
                                    .read(formDataProvider.notifier)
                                    .updateMerchantName(merchantName);
                                merchantNameController.text =
                                    merchantName; // Assuming you have a controller for it
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0), // Change from height to width
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text("Pick QR Image"),
                          onPressed: () async {
                            Map<String, String?>? qrDetails =
                                await _pickQRCodeImage();

                            if (qrDetails != null) {
                              String? upiId = qrDetails["upiId"];
                              String? merchantName = qrDetails["merchantName"];

                              if (upiId != null) {
                                ref
                                    .read(formDataProvider.notifier)
                                    .updateUpiId(upiId);
                                upiIdController.text = upiId;
                              }

                              if (merchantName != null) {
                                ref
                                    .read(formDataProvider.notifier)
                                    .updateMerchantName(merchantName);
                                merchantNameController.text =
                                    merchantName; // Assuming you have a controller for it
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16.0),

                Row(
                  children: [
                    Expanded(
                      child: Text('Currency:',
                          style: Theme.of(context).textTheme.bodyMedium),
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
                          ref
                              .read(formDataProvider.notifier)
                              .updateCurrency(newValue);
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
                                  ref
                                      .read(formDataProvider.notifier)
                                      .updateSelectedColor(color);
                                  Navigator.of(context).pop(color);
                                },
                              ),
                            ),
                          ),
                        );
                        if (color != null) {
                          ref
                              .read(formDataProvider.notifier)
                              .updateSelectedColor(color);
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
                          ref
                              .read(formDataProvider.notifier)
                              .toggleCreateShortcut();
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
                        value: accounts.archived || formData.toggleArchived,
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(formDataProvider.notifier)
                                .toggleArchived();
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
                child: Text('Delete',
                    style: TextStyle(
                        color: isDeletable ? Colors.red : Colors.grey)),
              ),
            TextButton(
              onPressed: () {
                if (accounts == null) {
                  _addAccounts(ref);
                } else {
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
    await ref
        .read(accountsProvider.notifier)
        .addAccount(accounts); // Use the provider to add
    _manageQuickActions();

    // await accountsBox.put(id, accounts);
    if (formData.createShortcut) {
      _createQuickAction(accounts);
    }
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

  Future<void> _updateAccounts(Accounts account, ref) async {
    final formData = ref.watch(formDataProvider);
    account.merchantName = formData.merchantName;
    account.upiId = formData.upiId;
    account.currency = formData.currency;
    account.color = formData.selectedColor.value;
    account.createShortcut = formData.createShortcut;
    account.archived = formData.toggleArchived;

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

  void _importProductForm(Accounts accounts, BuildContext context) async {
    final Uri url = Uri.parse(
      'https://staticapis.pragament.com/products/categorized_products.json',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Loading..."),
            ],
          ),
        );
      },
    );

    try {
      final response = await http.get(url);
      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode != 200) {
        throw Exception("Failed to load data: ${response.statusCode}");
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final List categories = data['categories'];
      List subcategories = [];
      List products = [];

      for (var category in categories) {
        final categoryId = category['category_id'];
        final categoryName = category['category'];
        final List subcats = category['subcategories'] ?? [];

        for (var subcategory in subcats) {
          final subcategoryId = subcategory['subcategory_id'];
          final subcategoryName = subcategory['subcategory'];
          final List prods = subcategory['products'] ?? [];

          subcategories.add({
            'id': subcategoryId,
            'name': subcategoryName,
            'category': {'id': categoryId}
          });

          for (var product in prods) {
            products.add({
              'id': product['product_id'],
              'name': product['product_name'],
              'price': double.tryParse(product['price'].toString()) ?? 0,
              'description': product['description'] ?? '',
              'imageUrl': product['image_url'] ?? '',
              'measurement': product['measurement'] ?? {},
              'subcategory': {
                'id': subcategoryId,
                'name': subcategoryName,
                'category': {
                  'id': categoryId,
                  'name': categoryName,
                }
              }
            });
          }
        }
      }

      String? selectedCategory;
      String? selectedSubcategory;
      Set<int> selectedProductIds = {};
      Map<String, TextEditingController> priceControllers = {};

      for (var product in products) {
        final productId = product['id'].toString();
        priceControllers[productId] = TextEditingController(
          text: product['price'].toString(),
        );
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Import Products'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                List filteredProducts = products.where((product) {
                  final subcategory = product['subcategory'];
                  final category = subcategory?['category'];
                  if (selectedCategory != null &&
                      category?['id'] != selectedCategory) {
                    return false;
                  }
                  if (selectedSubcategory != null &&
                      subcategory?['id'] != selectedSubcategory) {
                    return false;
                  }
                  return true;
                }).toList();

                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 50.0,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final catId = category['category_id'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCategory = catId;
                                  selectedSubcategory = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: selectedCategory == catId
                                      ? Colors.blue
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    category['category'],
                                    style: TextStyle(
                                      color: selectedCategory == catId
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: ListView.builder(
                                itemCount: subcategories.length,
                                itemBuilder: (context, index) {
                                  final subcategory = subcategories[index];
                                  final category = subcategory['category'];

                                  if (selectedCategory != null &&
                                      category?['id'] != selectedCategory) {
                                    return const SizedBox.shrink();
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedSubcategory = subcategory['id'];
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 8),
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      decoration: BoxDecoration(
                                        color: selectedSubcategory ==
                                            subcategory['id']
                                            ? Colors.blue
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        subcategory['name'],
                                        style: TextStyle(
                                          color: selectedSubcategory ==
                                              subcategory['id']
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: filteredProducts.map((product) {
                                    final productId = product['id'].toString();
                                    final isSelected = selectedProductIds
                                        .contains(productId.hashCode);

                                    return Row(
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              final idHash = productId.hashCode;
                                              if (value == true) {
                                                selectedProductIds.add(idHash);
                                              } else {
                                                selectedProductIds.remove(idHash);
                                              }
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(product['name']),
                                              TextFormField(
                                                controller:
                                                priceControllers[productId],
                                                keyboardType:
                                                TextInputType.number,
                                                decoration:
                                                const InputDecoration(
                                                  labelText: 'Price',
                                                ),
                                                onChanged: (value) {
                                                  final parsed =
                                                  double.tryParse(value);
                                                  if (parsed == null) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Please enter a valid numeric price.'),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Import'),
                onPressed: () async {
                  Navigator.of(context).pop();

                  final productBox = Hive.box<Product>('products');
                  for (var productId in selectedProductIds) {
                    final matchedProduct = products.firstWhere((product) =>
                    product['id'].toString().hashCode == productId);

                    final key = matchedProduct['id'].toString();
                    final controller = priceControllers[key];
                    final price = double.tryParse(controller?.text ?? '');

                    if (price == null || price <= 0) {
                      print("Invalid price for product ${matchedProduct['name']}");
                      continue;
                    }

                    final newProduct = Product(
                      id: productId,
                      name: matchedProduct['name'],
                      price: price,
                      description: matchedProduct['description'] ?? '',
                      imageUrl: matchedProduct['imageUrl'] ?? '',
                    );
                    log(newProduct.name);

                    productBox.put(productId, newProduct);
                  }

                  accounts.productIds.addAll(selectedProductIds);
                  Hive.box<Accounts>('accounts').put(accounts.key, accounts);
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      Navigator.of(context).pop();
      print("Error fetching or processing data: $e");
    }
  }
}


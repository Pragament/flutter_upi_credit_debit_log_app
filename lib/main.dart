import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/upi/model/pay.dart';
import 'package:flutter_template/upi/provider/riverpod_provider.dart';
import 'package:flutter_template/upi/screens/create_order_screen.dart';
import 'package:flutter_template/upi/screens/main_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quick_actions/quick_actions.dart';

import 'app.dart';
import 'flavors/flavor_config.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // const flavor = String.fromEnvironment("flavor", defaultValue: "dev");
  //
  // await dotenv.load(
  //   fileName: getEnvFileName(flavor),
  // );
  //
  // FlavorConfig.initialize(flavorString: flavor);
  // startApp();
  WidgetsFlutterBinding.ensureInitialized();

  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  Hive.registerAdapter(OrderAdapter());
  Hive.registerAdapter(AccountsAdapter());
  Hive.registerAdapter(ProductAdapter());

  await Hive.openBox<Order>('orders');
  await Hive.openBox<Accounts>('accounts');
  await Hive.openBox<Product>('products');

  runApp(const ProviderScope(child: MyApp()));


}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigatorKey = ref.watch(navigatorKeyProvider);
    // final quickActions = ref.read(quickActionsProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}


String getEnvFileName(String flavor) {
  switch (flavor) {
    case "prod":
      return ".env";
    case "qa":
      return ".env.qa";
    default:
      return ".env.dev";
  }
}


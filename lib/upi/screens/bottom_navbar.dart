import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/upi/screens/home_screen1.dart';
import 'package:hive/hive.dart';
import 'package:quick_actions/quick_actions.dart';

import '../model/pay.dart';
import '../provider/riverpod_provider.dart';
import 'home_screen.dart';
import 'transaction_screen.dart';

class KBottom extends ConsumerWidget {
  final QuickActions quickActions;

  const KBottom({
    Key? key,
    required this.quickActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPageIndex = ref.watch(selectedPageIndexProvider); // Watch page index
    final pageController = ref.watch(pageControllerProvider); // Get the PageController

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // Customize the app bar color
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(CupertinoIcons.house_fill),
              title: const Text('Home'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                ref.read(selectedPageIndexProvider.notifier).state = 0;
                pageController.jumpToPage(0);
              },
            ),
            ListTile(
              leading: Icon(CupertinoIcons.add),
              title: const Text('Transactions List'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                ref.read(selectedPageIndexProvider.notifier).state = 1;
                pageController.jumpToPage(1);
              },
            ),
          ],
        ),
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          ref.read(selectedPageIndexProvider.notifier).state = index;
        },
        children: [
          HomeScreen(
            quickActions: quickActions,
          ),
          HomeScreen1(
            quickActions: quickActions,
          ),
          const TransactionScreen(),
          const Scaffold(
            body: Center(
              child: Text("Settings"),
            ),
          )
        ],
      ),
    );
  }
}


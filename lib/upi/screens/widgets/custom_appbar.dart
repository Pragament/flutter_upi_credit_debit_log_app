import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/notifiers.dart';
import '../../provider/riverpod_provider.dart';


AppBar customAppBar(WidgetRef ref, TextEditingController searchController) {
  final isAscending = ref.watch(sortOrderProvider);
  final showArchived = ref.watch(showArchivedProvider);

  return AppBar(
    title: const Text('Home'),
    actions: [
      IconButton(
        icon: Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward),
        onPressed: () => _toggleSortOrder(ref, isAscending),
      ),
      IconButton(
        icon: Icon(showArchived ? Icons.archive : Icons.archive_outlined),
        onPressed: () {
          ref.read(showArchivedProvider.notifier).state = !showArchived;

          ScaffoldMessenger.of(ref.context).showSnackBar(
            SnackBar(
              content: Text(
                showArchived
                    ? 'Showing archived accounts & products'
                    : 'Hiding archived accounts & products',
              ),
            ),
          );
        },
      ),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(56.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search Accounts or Products',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          onChanged: (value) {
            ref.read(searchQueryProviders.notifier).updateQuery(value);
            ref.read(searchControllerProvider.notifier).updateText(value);
          },
        ),
      ),
    ),
  );
}

void _toggleSortOrder(WidgetRef ref, bool isAscending) {
  isAscending = !isAscending;
  ref.read(sortOrderProvider.notifier).state = isAscending;
  ScaffoldMessenger.of(ref.context).showSnackBar(
    SnackBar(
      content: Text(
        isAscending
            ? 'Sorting by account in ascending order'
            : 'Sorting by account in descending order',
      ),
    ),
  );
}

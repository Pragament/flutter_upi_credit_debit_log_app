import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/tag/tag_model.dart';
import 'package:flutter_template/tag/tags_provider.dart';
import 'package:uuid/uuid.dart';

class TagsSelectionDialog extends ConsumerStatefulWidget {
  const TagsSelectionDialog({super.key, required this.selectedTags});
  final List<Tag> selectedTags;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TagsSelectionDialogState();
}

class _TagsSelectionDialogState extends ConsumerState<TagsSelectionDialog> {
  List<Tag> selectedTags = [];
  List<Tag> filteredTags = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    selectedTags = widget.selectedTags;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final allTags = ref.watch(tagsNotifierProvider);
    filteredTags = allTags.where((tag) {
      return tag.name
          .toLowerCase()
          .contains(searchController.text.toLowerCase());
    }).toList();
    return SizedBox(
      height: 500,
      width: 400,
      child: AlertDialog(
        scrollable: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select a Tag:',
              style: TextStyle(fontSize: 15),
            ),
            InkWell(
              onTap: () {
                final tagNameC = TextEditingController();
                final formKey = GlobalKey<FormState>();

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Enter tag name",
                        textAlign: TextAlign.center),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20.0))),
                    backgroundColor: Theme.of(context).dialogBackgroundColor,
                    titlePadding: const EdgeInsets.only(top: 27),
                    insetPadding: EdgeInsets.zero,
                    contentPadding: const EdgeInsets.only(top: 10),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    content: SizedBox(
                      height: 125,
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(5)),
                                child: TextFormField(
                                  controller: tagNameC,
                                  autofocus: true,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  cursorColor: Theme.of(context).focusColor,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Cannot be empty';
                                    }
                                    return null;
                                  },
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.tag),
                                  ),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                elevation: 0.0,
                                shadowColor: Colors.transparent,
                              ),
                              onPressed: () async {
                                if (formKey.currentState?.validate() ?? false) {
                                  await ref
                                      .read(tagsNotifierProvider.notifier)
                                      .add(Tag(
                                          id: const Uuid().v1(),
                                          name: tagNameC.text));
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('Create'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              // Changed the widget to text
              child: const Text(
                "Create Tag +",
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        content: Column(
          children: [
            // Search bar
            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Search...',
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            filteredTags.isEmpty
                ? const Text('No tags exist.\nTap + icon to create a new tag.')
                : SizedBox(
                    height: 250,
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(
                          filteredTags.length,
                          (index) {
                            final tag = filteredTags[index];

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Material(
                                elevation: 2,
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[100],
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: CheckboxListTile(
                                        title: Text(
                                          "# ${tag.name}",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        value: selectedTags
                                            .map((e) => e.id)
                                            .contains(tag.id),
                                        onChanged: (enabled) => setState(
                                          () => enabled ?? false
                                              ? selectedTags.add(tag)
                                              : selectedTags.remove(tag),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          await ref
                                              .read(
                                                  tagsNotifierProvider.notifier)
                                              .remove(tag);
                                          setState(() {});
                                        })
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context, selectedTags);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

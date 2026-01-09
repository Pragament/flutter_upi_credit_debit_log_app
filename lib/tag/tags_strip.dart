import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/tag/home_state_provider.dart';
import 'package:flutter_template/tag/tag_model.dart';
import 'package:flutter_template/tag/tags_provider.dart';

class TagsStrip extends ConsumerWidget {
  const TagsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTags = ref.watch(tagsNotifierProvider);
    final selectedTags = ref.watch(homeStateNotifierProvider).selectedTags;

    return allTags.isEmpty
        ? SizedBox.shrink()
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: SizedBox(
                      height: 35,
                      child: FittedBox(
                          fit: BoxFit.contain,
                          child: FilterChip(
                            padding: const EdgeInsets.all(4.0),
                            showCheckmark: false,
                            label: Row(
                              children: [
                                Icon(selectedTags.isEmpty
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank),
                                const Text(' All',
                                    style: TextStyle(fontSize: 18)),
                              ],
                            ),
                            selected: selectedTags.isEmpty,
                            onSelected: (_) {
                              ref
                                  .read(homeStateNotifierProvider.notifier)
                                  .updateTagSelection([]);
                            },
                          ))),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      allTags.length,
                      (index) {
                        final tag = allTags.elementAt(index);
                        final isSelected =
                            selectedTags.map((e) => e.id).contains(tag.id);
                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: SizedBox(
                            height: 35,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: FilterChip(
                                padding: const EdgeInsets.all(4.0),
                                showCheckmark: false,
                                label: Row(
                                  children: [
                                    Icon(isSelected
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank),
                                    Text(' ${tag.name}',
                                        style: const TextStyle(fontSize: 18)),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  final tags = List<Tag>.from(selectedTags);
                                  if (selected) {
                                    tags.add(tag);
                                  } else {
                                    tags.removeWhere((t) => t.id == tag.id);
                                  }
                                  ref
                                      .read(homeStateNotifierProvider.notifier)
                                      .updateTagSelection(tags);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}

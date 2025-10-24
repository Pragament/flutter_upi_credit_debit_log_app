import 'package:flutter_template/tag/tag_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tags_provider.g.dart';

@riverpod
class TagsNotifier extends _$TagsNotifier {
  late Box<Tag> _box;

  @override
  List<Tag> build() {
    _box = Hive.box<Tag>('tags');
    return _box.values.toList();
  }

  Future<void> add(Tag tag) async {
    await _box.put(tag.id, tag);
    state = [...state, tag];
  }

  Future<void> remove(Tag tag) async {
    await _box.delete(tag.id);
    state = state.where((item) => item.id != tag.id).toList();
  }

  Future<void> update(Tag tag) async {
    await _box.put(tag.id, tag);
    state = [
      for (final existingTag in state)
        if (existingTag.id == tag.id) tag else existingTag
    ];
  }
}

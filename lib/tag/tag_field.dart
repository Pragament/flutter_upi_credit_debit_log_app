import 'package:flutter/material.dart';
import 'package:flutter_template/tag/tag_model.dart';
import 'package:flutter_template/tag/tags_selection_dialog.dart';

class DynamicTagField extends StatefulWidget {
  const DynamicTagField({
    super.key,
    this.initialTags = const [],
    this.onTagsChanged,
  });

  final List<Tag> initialTags;
  final Function(List<Tag>)? onTagsChanged;

  @override
  State<DynamicTagField> createState() => _DynamicTagFieldState();
}

class _DynamicTagFieldState extends State<DynamicTagField> {
  late List<Tag> _selectedTags;

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialTags);
  }

  @override
  void didUpdateWidget(DynamicTagField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTags != widget.initialTags) {
      _selectedTags = List.from(widget.initialTags);
    }
  }

  void _openTagSelectionDialog() async {
    final resultTags = await showDialog<List<Tag>>(
      context: context,
      builder: (context) => TagsSelectionDialog(selectedTags: _selectedTags),
    );

    if (resultTags != null) {
      setState(() {
        _selectedTags = List.from(resultTags);
      });
      widget.onTagsChanged?.call(_selectedTags);
    }
  }

  void _removeTag(Tag tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
    widget.onTagsChanged?.call(_selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = 20.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.tag, color: Colors.grey),
          const SizedBox(width: 8),
          const Text(
            "Tags:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _selectedTags.map((tag) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilterChip(
                      label: Text('# ${tag.name}'),
                      selected: true,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                      onSelected: (_) => _removeTag(tag),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Add Tag Button
          IconButton(
            onPressed: _openTagSelectionDialog,
            tooltip: "Add/Select Tags",
            icon: Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

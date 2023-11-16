import 'package:flutter/material.dart';

class TagPreview extends StatefulWidget {
  final String tag;
  final Function onRemove;

  const TagPreview({super.key, required this.tag, required this.onRemove});

  @override
  State<TagPreview> createState() => _TagPreviewState();
}

class _TagPreviewState extends State<TagPreview> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2.5, 0, 2.5, 0),
      child: Chip(
        label: Text(
          widget.tag,
          style: Theme.of(context).textTheme.labelLarge?.apply(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
        ),
        side: BorderSide.none,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        deleteIcon: Icon(
          Icons.clear_outlined,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        onDeleted: () {
          widget.onRemove();
        },
      ),
    );
  }
}

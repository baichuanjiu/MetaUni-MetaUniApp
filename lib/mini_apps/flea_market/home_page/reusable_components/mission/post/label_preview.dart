import 'package:flutter/material.dart';

class LabelPreview extends StatefulWidget {
  final MapEntry<String, String> label;
  final Function onRemove;

  const LabelPreview({super.key, required this.label, required this.onRemove});

  @override
  State<LabelPreview> createState() => _LabelPreviewState();
}

class _LabelPreviewState extends State<LabelPreview> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 5, 0, 5),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      "${widget.label.key}  ",
                      style: Theme.of(context).textTheme.bodyMedium?.apply(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      widget.label.value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              widget.onRemove();
            },
            icon: const Icon(
              Icons.backspace_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

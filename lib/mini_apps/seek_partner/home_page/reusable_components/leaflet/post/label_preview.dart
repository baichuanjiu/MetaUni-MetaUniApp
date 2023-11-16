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
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "${widget.label.key}  ",
                    style: Theme.of(context).textTheme.bodyLarge?.apply(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  TextSpan(
                    text: widget.label.value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
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

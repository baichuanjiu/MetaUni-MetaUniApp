import 'package:flutter/material.dart';

class Label extends StatefulWidget {
  final MapEntry<String, String> label;

  const Label({super.key, required this.label});

  @override
  State<Label> createState() => _LabelState();
}

class _LabelState extends State<Label> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
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
    );
  }
}

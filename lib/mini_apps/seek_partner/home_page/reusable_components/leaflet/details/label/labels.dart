import 'package:flutter/material.dart';
import 'label.dart';

class Labels extends StatelessWidget {
  final Map<String, String> labels;

  const Labels({super.key, required this.labels});

  @override
  Widget build(BuildContext context) {
    List<Label> labelList = [];

    labels.forEach(
      (key, value) {
        labelList.add(
          Label(
            label: MapEntry(key, value),
          ),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: labelList,
    );
  }
}

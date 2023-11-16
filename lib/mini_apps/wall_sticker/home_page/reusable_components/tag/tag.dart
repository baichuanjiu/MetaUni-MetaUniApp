import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../reusable_components/snack_bar/normal_snack_bar.dart';

class Tag extends StatelessWidget {
  final String text;

  const Tag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: "#$text"));
        getNormalSnackBar(context, "复制成功");
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2.5, 0, 2.5, 0),
        child: Text(
          "#$text",
          style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

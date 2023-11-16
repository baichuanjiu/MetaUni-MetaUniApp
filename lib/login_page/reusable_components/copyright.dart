import 'package:flutter/material.dart';

class Copyright extends StatelessWidget {
  const Copyright({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.copyright_rounded,
          color: Theme.of(context).colorScheme.onSurface,
          size: 20,
        ),
        Text(' 2023 WebDev403', style: Theme.of(context).textTheme.bodyMedium?.apply(color: Theme.of(context).colorScheme.onSurface))
      ],
    );
  }
}

import 'package:flutter/material.dart';

class IntroductionReadme extends StatelessWidget {
  final String readme;

  const IntroductionReadme({required this.readme, super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "开发者说",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              height: 10,
            ),
            SelectableText(
              readme,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class IntroductionPreview extends StatelessWidget {
  final List<Widget> preview;

  const IntroductionPreview({required this.preview, super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "预览",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              height: 16,
            ),
            Container(
              constraints: const BoxConstraints(
                maxHeight: 350,
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: preview,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

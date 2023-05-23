import 'package:flutter/material.dart';

class Stars extends StatelessWidget {
  final Color color;
  final int numberOfStars;

  const Stars({required this.color, required this.numberOfStars, super.key});

  @override
  Widget build(BuildContext context) {
    switch (numberOfStars) {
      case 5:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
          ],
        );
      case 4:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
          ],
        );
      case 3:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
          ],
        );
      case 2:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
          ],
        );
      case 1:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
          ],
        );
      default:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: color,
            ),
          ],
        );
    }
  }
}
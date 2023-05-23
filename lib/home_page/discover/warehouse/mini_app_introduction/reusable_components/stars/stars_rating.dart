import 'package:flutter/material.dart';

class StarsRating extends StatelessWidget {
  final Color fillColor;
  final Color backgroundColor;
  final int numberOfStars;

  const StarsRating({required this.fillColor, required this.backgroundColor, required this.numberOfStars, super.key});

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
              color: fillColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: fillColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: fillColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: fillColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: fillColor,
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
              color: fillColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: fillColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: fillColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: fillColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: backgroundColor,
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
              color: fillColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: fillColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: fillColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: backgroundColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: backgroundColor,
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
              color: fillColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: fillColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: backgroundColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: backgroundColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: backgroundColor,
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
              color: fillColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: backgroundColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: backgroundColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: backgroundColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: backgroundColor,
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
              color: backgroundColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: backgroundColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: backgroundColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: backgroundColor,
            ),
            Icon(
              Icons.star_outlined,
              size: 12,
              color: backgroundColor,
            ),
          ],
        );
    }
  }
}
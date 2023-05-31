String getFormattedInt(int number) {
  if (number >= 100000) {
    return "${(number / 10000).round()}W";
  } else if (number >= 1000) {
    return "${(number / 1000).round()}K";
  } else {
    return number.toString();
  }
}

String getFormattedDouble(double number) {
  if (number >= 100000) {
    return "${(number / 10000).toStringAsFixed(1)}W";
  } else if (number >= 1000) {
    return "${(number / 1000).toStringAsFixed(1)}K";
  } else {
    return number.toStringAsFixed(1);
  }
}

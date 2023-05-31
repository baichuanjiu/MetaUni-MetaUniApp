String getFormattedDateTime({required DateTime dateTime, bool shouldShowTime = false}) {
  DateTime now = DateTime.now();
  if (now.year == dateTime.year)
  {
    if (now.month == dateTime.month)
    {
      if (now.day == dateTime.day)
      {
        return dateTime.toString().substring(11, 16);
      }
      else
      {
        if (shouldShowTime)
        {
          return "${dateTime.month}月${dateTime.day}日 ${dateTime.toString().substring(11, 16)}";
        }
        else
        {
          return "${dateTime.month}月${dateTime.day}日";
        }
      }
    }
    else
    {
      if (shouldShowTime)
      {
        return "${dateTime.month}月${dateTime.day}日 ${dateTime.toString().substring(11, 16)}";
      }
      else
      {
        return "${dateTime.month}月${dateTime.day}日";
      }
    }
  }
  else
  {
    if (shouldShowTime)
    {
      return "${dateTime.year}年${dateTime.month}月${dateTime.day}日 ${dateTime.toString().substring(11, 16)}";
    }
    else
    {
      return "${dateTime.year}年${dateTime.month}月${dateTime.day}日";
    }
  }
}

String getFormattedDateTime({required DateTime dateTime, bool shouldShowTime = false}) {
  DateTime now = DateTime.now();
  dateTime = dateTime.toLocal();

  //如果不要求显示时间的话
  if(!shouldShowTime){
    //目标时间在现在之前
    if(now.isAfter(dateTime))
    {
      int millisecondsGap = now.millisecondsSinceEpoch - dateTime.millisecondsSinceEpoch;
      //七天内
      if(millisecondsGap <= 604800000)
      {
        //一天内
        if(millisecondsGap <= 86400000)
        {
          //一小时内
          if(millisecondsGap <= 3600000)
          {
            if(millisecondsGap <= 180000)
            {
              //相距三分钟内，显示刚刚
              return "刚刚";
            }
            //相距一小时内，显示XX分钟前
            return "${(millisecondsGap / 60000).round()}分钟前";
          }
          //相距一天内，显示XX小时前
          return "${(millisecondsGap / 3600000).round()}小时前";
        }
        //相距七天内，显示X天前
        return "${(millisecondsGap / 86400000).round()}天前";
      }
    }
    //目标时间在现在之后
    else
    {
      int millisecondsGap = dateTime.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
      //七天内
      if(millisecondsGap <= 604800000)
      {
        //一天内
        if(millisecondsGap <= 86400000)
        {
          //一小时内
          if(millisecondsGap <= 3600000)
          {
            //相距一小时内，显示XX分钟后
            return "${(millisecondsGap / 60000).round()}分钟后";
          }
          //相距一天内，显示XX小时后
          return "${(millisecondsGap / 3600000).round()}小时后";
        }
        //相距七天内，显示X天后
        return "${(millisecondsGap / 86400000).round()}天后";
      }
    }
    //相距七天以上
    //同一年
    if (now.year == dateTime.year)
    {
      //同一年，显示XX月XX日
      return "${dateTime.month}月${dateTime.day}日";
    }
    //不是同一年，显示XXXX年XX月XX日
    return "${dateTime.year}年${dateTime.month}月${dateTime.day}日";
  }
  //如果要求显示时间的话
  else
  {
    //同一年
    if (now.year == dateTime.year) {
      //同一月
      if (now.month == dateTime.month) {
        //同一天
        if (now.day == dateTime.day)
        {
          //目标时间在现在之前
          if(now.isAfter(dateTime))
          {
            int millisecondsGap = now.millisecondsSinceEpoch - dateTime.millisecondsSinceEpoch;
            //一小时内
            if(millisecondsGap <= 3600000)
            {
              if(millisecondsGap <= 180000)
              {
                //相距三分钟内，显示刚刚
                return "刚刚";
              }
              //相距一小时内，显示XX分钟前
              return "${(millisecondsGap / 60000).round()}分钟前";
            }
          }
          //目标时间在现在之后
          else
          {
            int millisecondsGap = dateTime.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
            //一小时内
            if(millisecondsGap <= 3600000)
            {
              //相距一小时内，显示XX分钟后
              return "${(millisecondsGap / 60000).round()}分钟后";
            }
          }
          //相距一小时以上
          //同一天，显示时间
          return dateTime.toString().substring(11, 16);
        }
        //同一月但不是同一天，显示XX月XX日与时间
        return "${dateTime.month}月${dateTime.day}日 ${dateTime.toString().substring(11, 16)}";
      }
      //同一年但不是同一月，显示XX月XX日与时间
      return "${dateTime.month}月${dateTime.day}日 ${dateTime.toString().substring(11, 16)}";
    }
    //不是同一年，显示XXXX年XX月XX日与时间
    return "${dateTime.year}年${dateTime.month}月${dateTime.day}日 ${dateTime.toString().substring(11, 16)}";
  }
}

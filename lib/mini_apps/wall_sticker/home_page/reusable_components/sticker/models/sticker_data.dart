import '../../../models/brief_user_info/brief_user_info.dart';
import '../../media/models/media_metadata.dart';

class StickerData {
  late String id;
  late BriefUserInfo briefUserInfo;
  late bool isAnonymous;
  late bool isDeleted;
  late DateTime createdTime;
  late String? replyTo;
  late String text;
  late List<String> tags;
  late List<MediaMetadata> medias;
  late bool isLiked;
  late int likesNumber;
  late int repliesNumber;
  late double trendValue;

  StickerData.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    briefUserInfo = BriefUserInfo.fromJson(map['briefUserInfo']);
    isAnonymous = map['isAnonymous'];
    isDeleted = map['isDeleted'];
    createdTime = DateTime.parse(map['createdTime']);
    replyTo = map['replyTo'];
    text = map['text'];
    tags = [];
    for(String tag in map['tags'])
    {
      tags.add(tag);
    }
    medias = [];
    for(var media in map['medias'])
    {
      medias.add(MediaMetadata.fromJson(media),);
    }
    isLiked = map['isLiked'];
    likesNumber = map['likesNumber'];
    repliesNumber = map['repliesNumber'];
    trendValue = double.parse(map['trendValue'].toString());
  }
}

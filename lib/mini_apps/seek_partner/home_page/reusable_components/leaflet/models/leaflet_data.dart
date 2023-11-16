import 'package:meta_uni_app/mini_apps/seek_partner/home_page/models/brief_user_info/brief_user_info.dart';

import '../../../models/media/media_metadata.dart';

class LeafletData {
  late String id;
  late BriefUserInfo poster;
  late String title;
  late String description;
  late Map<String, String> labels;
  late List<String> tags;
  late List<MediaMetadata> medias;
  late String channel;
  late DateTime createdTime;
  late DateTime deadline;
  late bool isDeleted;

  LeafletData.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    poster = BriefUserInfo.fromJson(map['poster']);
    title = map['title'];
    description = map['description'];
    labels = {};
    (map['labels'] as Map<String,dynamic>).forEach((key, value)
    {
      labels.addEntries([MapEntry(key, value)]);
    });
    tags = [];
    for (String tag in map['tags']) {
      tags.add(tag);
    }
    medias = [];
    for (var media in map['medias']) {
      medias.add(
        MediaMetadata.fromJson(media),
      );
    }
    channel = map['channel'];
    createdTime = DateTime.parse(map['createdTime']);
    deadline = DateTime.parse(map['deadline']);
    isDeleted = map['isDeleted'];
  }
}

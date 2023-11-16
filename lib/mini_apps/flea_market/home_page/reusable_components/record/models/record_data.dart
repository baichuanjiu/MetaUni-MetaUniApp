import 'package:meta_uni_app/mini_apps/flea_market/home_page/models/brief_user_info/brief_user_info.dart';
import 'package:meta_uni_app/mini_apps/flea_market/home_page/models/media/media_metadata.dart';
import '../../../models/price/price_data.dart';
import '../../channel/models/channel_data.dart';

class BriefRecordData {
  late String id;
  late String type; // sell(出售) purchase(购买)
  late BriefUserInfo user;
  late String title;
  late MediaMetadata? cover;
  late String? campus; //屯溪路 翡翠湖 宣城
  late List<String> tags; //RecordData中的Labels去掉Key组成
  late DateTime createdTime;
  late double price;
  late String remark;

  BriefRecordData.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    type = map['type'];
    user = BriefUserInfo.fromJson(map['user']);
    title = map['title'];
    if (map['cover'] != null) {
      cover = MediaMetadata.fromJson(map['cover']);
    } else {
      cover = null;
    }
    campus = map['campus'];
    tags = [];
    for (String tag in map['tags']) {
      tags.add(tag);
    }
    createdTime = DateTime.parse(map['createdTime']);
    price = double.parse(map['price'].toString());
    remark = map['remark'];
  }
}

class RecordData {
  late String id;
  late String type; // sell(出售) purchase(购买)
  late BriefUserInfo user;
  late String title;
  late String? campus; //屯溪路 翡翠湖 宣城
  late String description;
  late Map<String, String> labels;
  late List<MediaMetadata> medias;
  late bool isDeleted;
  late DateTime createdTime;
  late double price;
  late String remark;

  RecordData.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    type = map['type'];
    user = BriefUserInfo.fromJson(map['user']);
    title = map['title'];
    campus = map['campus'];
    description = map['description'];
    labels = {};
    (map['labels'] as Map<String, dynamic>).forEach((key, value) {
      labels.addEntries([MapEntry(key, value)]);
    });
    medias = [];
    for (var media in map['medias']) {
      medias.add(
        MediaMetadata.fromJson(media),
      );
    }
    isDeleted = map['isDeleted'];
    createdTime = DateTime.parse(map['createdTime']);
    price = double.parse(map['price'].toString());
    remark = map['remark'];
  }
}

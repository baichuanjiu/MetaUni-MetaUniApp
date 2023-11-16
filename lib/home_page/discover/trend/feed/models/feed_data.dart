class MediaMetadata {
  late String type; //"image" or "video"
  late String url;
  late double aspectRatio; //长宽比
  late String? previewImage; //only video
  late Duration? timeTotal; //only video

  MediaMetadata({required this.type, required this.url, required this.aspectRatio, this.previewImage, this.timeTotal});

  MediaMetadata.fromJson(Map<String, dynamic> map) {
    type = map['type'];
    url = map['url'];
    aspectRatio = double.parse(
      map['aspectRatio'].toString(),
    );
    previewImage = map['previewImage'];
    if (map['timeTotal'] != null) {
      timeTotal = Duration(milliseconds: map['timeTotal']);
    }
  }
}

class BriefMiniAppInfo
{
  late String id;
  late String avatar;
  late String type;
  late String name;

  BriefMiniAppInfo.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    avatar = map['avatar'];
    type = map['type'];
    name = map['name'];
  }
}

class FeedData
{
  late String id;
  late MediaMetadata? cover;
  late String previewContent;
  late BriefMiniAppInfo briefMiniAppInfo;
  late String title;
  late String description;
  late String openPageUrl;

  FeedData.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    if (map['cover'] != null) {
      cover = MediaMetadata.fromJson(map['cover']);
    } else {
      cover = null;
    }
    previewContent = map['previewContent'];
    briefMiniAppInfo = BriefMiniAppInfo.fromJson(map['briefMiniAppInfo']);
    title = map['title'];
    description = map['description'];
    openPageUrl = map['openPageUrl'];
  }
}
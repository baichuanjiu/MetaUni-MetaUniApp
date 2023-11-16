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

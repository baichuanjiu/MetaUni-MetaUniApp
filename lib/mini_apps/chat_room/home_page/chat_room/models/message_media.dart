class MessageMedia {
  late String type;
  late String url;
  late double aspectRatio;
  late String? previewImage;
  late Duration? timeTotal; //milliseconds

  MessageMedia.fromJson(Map<String, dynamic> map) {
    type = map['type'];
    url = map['url'];
    aspectRatio = double.parse(
      map['aspectRatio'].toString(),
    );
    if (type == 'video') {
      previewImage = map['previewImage'];
      timeTotal = Duration(
        milliseconds: map['timeTotal'],
      );
    } else {
      previewImage = null;
      timeTotal = null;
    }
  }
}

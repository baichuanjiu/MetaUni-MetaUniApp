class MediaMetadata {
  late String url;
  late double aspectRatio; //长宽比

  MediaMetadata({required this.url, required this.aspectRatio});

  MediaMetadata.fromJson(Map<String, dynamic> map) {
    url = map['url'];
    aspectRatio = double.parse(
      map['aspectRatio'].toString(),
    );
  }
}

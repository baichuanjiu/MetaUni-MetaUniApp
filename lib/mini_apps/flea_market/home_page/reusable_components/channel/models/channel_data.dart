class ChannelData {
  late String mainChannel;
  late String? subChannel;

  ChannelData({required this.mainChannel, this.subChannel});

  ChannelData.fromJson(Map<String, dynamic> map) {
    mainChannel = map['mainChannel'];
    subChannel = map['subChannel'];
  }

  Map<String, dynamic> toJson() {
    return {
      'mainChannel': mainChannel,
      'subChannel': subChannel,
    };
  }

  @override
  String toString() {
    if (subChannel == null) {
      return mainChannel;
    } else {
      return "$mainChannel - $subChannel";
    }
  }
}

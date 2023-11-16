class MiniAppInformation {
  late String id;
  late String type;
  late String name;
  late String avatar;
  late String description;
  late String backgroundImage;
  late double trendValue;

  MiniAppInformation({
    required this.id,
    required this.type,
    required this.name,
    required this.avatar,
    required this.description,
    required this.backgroundImage,
    required this.trendValue,
  });

  MiniAppInformation.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    type = map['type'];
    name = map['name'];
    avatar = map['avatar'];
    description = map['description'];
    backgroundImage = map['backgroundImage'];
    trendValue = double.parse(map['trendValue'].toString());
  }
}
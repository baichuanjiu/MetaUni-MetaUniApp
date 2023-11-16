class WebApp {
  late String id;
  late String type = "ClientApp";
  late String name;
  late String avatar;
  late String description;
  late String backgroundImage;
  late String url;
  late double trendValue;

  WebApp({
    required this.id,
    required this.name,
    required this.avatar,
    required this.description,
    required this.backgroundImage,
    required this.url,
    required this.trendValue,
  });

  WebApp.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
    avatar = map['avatar'];
    description = map['description'];
    backgroundImage = map['backgroundImage'];
    url = map['url'];
    trendValue = double.parse(map['trendValue'].toString());
  }
}
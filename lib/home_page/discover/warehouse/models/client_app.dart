class ClientApp {
  late String id;
  late String type = "ClientApp";
  late String name;
  late String avatar;
  late String description;
  late String backgroundImage;
  late String routingURL;
  late String? url;
  late double trendingValue;
  late String minimumSupportVersion;

  ClientApp({
    required this.id,
    required this.name,
    required this.avatar,
    required this.description,
    required this.backgroundImage,
    required this.routingURL,
    required this.url,
    required this.trendingValue,
    required this.minimumSupportVersion
  });

  ClientApp.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
    avatar = map['avatar'];
    description = map['description'];
    backgroundImage = map['backgroundImage'];
    routingURL = map['routingURL'];
    url = map['url'];
    trendingValue = double.parse(map['trendingValue'].toString());
    minimumSupportVersion = map['minimumSupportVersion'];
  }
}
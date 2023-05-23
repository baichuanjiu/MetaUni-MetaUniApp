class MiniAppIntroduction {
  late String id;
  late String miniAppId;
  late List<int> stars;
  late String developer;
  late List<String> preview;
  late String guide;
  late String readme;

  MiniAppIntroduction({
    required this.id,
    required this.miniAppId,
    required this.stars,
    required this.developer,
    required this.preview,
    required this.guide,
    required this.readme
  });

  MiniAppIntroduction.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    miniAppId = map['miniAppId'];
    stars = List.from(map['stars']);
    developer = map['developer'];
    preview = List.from(map['preview']);
    guide = map['guide'];
    readme = map['readme'];
  }
}
class MiniAppReview {
  late String id;
  late String miniAppId;
  late int uuid;
  late String nickname;
  late int stars;
  late String title;
  late DateTime createdTime;
  late String content;

  MiniAppReview({
    required this.id,
    required this.miniAppId,
    required this.uuid,
    required this.nickname,
    required this.stars,
    required this.title,
    required this.createdTime,
    required this.content,
  });

  MiniAppReview.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    miniAppId = map['miniAppId'];
    uuid = map['uuid'];
    nickname = map['nickname'];
    stars = map['stars'];
    title = map['title'];
    createdTime = DateTime.parse(map['createdTime']);
    content = map['content'];
  }
}
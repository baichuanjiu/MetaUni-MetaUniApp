class Sender
{
  late int uuid;
  late String avatar;
  late String nickname;

  Sender.fromJson(Map<String, dynamic> map)
  {
    uuid = map['uuid'];
    avatar = map['avatar'];
    nickname = map['nickname'];
  }
}
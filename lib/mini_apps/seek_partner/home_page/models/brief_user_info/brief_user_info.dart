class BriefUserInfo {
  late int uuid;
  late String avatar;
  late String nickname;

  BriefUserInfo({required this.uuid, required this.avatar, required this.nickname});

  BriefUserInfo.fromJson(Map<String, dynamic> map) {
    uuid = map['uuid'];
    avatar = map['avatar'];
    nickname = map['nickname'];
  }
}

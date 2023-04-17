class BriefChatTargetInformation{
  late String targetType;
  late int uuid;
  late String avatar;
  late String name;
  late DateTime updatedTime;

  BriefChatTargetInformation({required this.targetType,required this.uuid,required this.avatar,required this.name,required this.updatedTime});

  BriefChatTargetInformation.fromJson(Map<String, dynamic> map) {
    targetType = map['targetType'];
    uuid = map['uuid'];
    avatar = map['avatar'];
    name = map['name'];
    updatedTime = DateTime.parse(map['updatedTime']);
  }
}
class BriefChatTargetInformation{
  late int? chatId;
  late String targetType;
  late int id;
  late String avatar;
  late String name;
  late DateTime updatedTime;

  BriefChatTargetInformation({required this.chatId,required this.targetType,required this.id,required this.avatar,required this.name,required this.updatedTime});

  BriefChatTargetInformation.fromJson(Map<String, dynamic> map) {
    chatId = map['chatId'];
    targetType = map['targetType'];
    id = map['id'];
    avatar = map['avatar'];
    name = map['name'];
    updatedTime = DateTime.parse(map['updatedTime']);
  }
}
class ReadMessagesRequestData {
  final String type = "ReadMessages";
  int uuid;
  String jwt;
  int chatId;

  ReadMessagesRequestData({
    required this.uuid,
    required this.jwt,
    required this.chatId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'uuid': uuid,
      'jwt': jwt,
      'data': {
        'ChatId': chatId,
      },
    };
  }
}

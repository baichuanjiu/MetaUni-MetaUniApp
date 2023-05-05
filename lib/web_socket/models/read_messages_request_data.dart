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
      'data': {
        'UUID': uuid,
        'JWT': jwt,
        'ChatId': chatId,
      },
    };
  }
}

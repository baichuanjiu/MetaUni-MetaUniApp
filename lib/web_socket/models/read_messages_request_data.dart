class ReadCommonMessagesRequestData {
  final String type = "ReadCommonMessages";
  int uuid;
  String jwt;
  int chatId;

  ReadCommonMessagesRequestData({
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

class ReadSystemMessagesRequestData {
  final String type = "ReadSystemMessages";
  int uuid;
  String jwt;
  int chatId;

  ReadSystemMessagesRequestData({
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
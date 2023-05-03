class ReadMessagesRequestData {
  final String type = "ReadMessages";
  int chatId;

  ReadMessagesRequestData({
    required this.chatId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'chatId': chatId,
    };
  }
}

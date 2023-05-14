class SyncCommonMessagesRequestData {
  final String type = "SyncCommonMessages";
  int uuid;
  String jwt;
  int sequence;

  SyncCommonMessagesRequestData({
    required this.uuid,
    required this.jwt,
    required this.sequence,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'uuid': uuid,
      'jwt': jwt,
      'data': {
        'Sequence': sequence,
      },
    };
  }
}

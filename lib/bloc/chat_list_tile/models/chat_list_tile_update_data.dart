class ChatListTileUpdateData {
  late int chatId;
  late bool messageBeRecalled;
  late int? messageBeRecalledId;
  late bool messageBeDeleted;
  late int? messageBeDeletedId;

  ChatListTileUpdateData({
    required this.chatId,
    this.messageBeRecalled = false,
    this.messageBeRecalledId,
    this.messageBeDeleted = false,
    this.messageBeDeletedId,
  });
}

import 'dart:io';

class MessageInputData {
  late String? messageText;
  late List<File> messageMedias;

  MessageInputData(this.messageText, this.messageMedias);
}
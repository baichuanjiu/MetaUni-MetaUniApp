import 'package:web_socket_channel/io.dart';

import '../bloc/message/common_message_bloc.dart';

//单例模式构建webSocketHelper
class WebSocketHelper {
  static final WebSocketHelper _instance = WebSocketHelper._();

  WebSocketHelper._();

  factory WebSocketHelper() {
    return _instance;
  }

  late int uuid;
  late String jwt;
  late CommonMessageCubit commonMessageCubit;

  initHelper(int uuid, String jwt,CommonMessageCubit commonMessageCubit) {
    this.uuid = uuid;
    this.jwt = jwt;
    this.commonMessageCubit = commonMessageCubit;
  }

}
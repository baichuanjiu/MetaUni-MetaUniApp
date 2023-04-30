import 'dart:convert';
import 'package:meta_uni_app/database/models/message/common_message.dart';
import 'package:meta_uni_app/web_socket/web_socket_helper.dart';
import 'package:web_socket_channel/io.dart';

//单例模式构建webSocket
class WebSocketChannel {
  static final WebSocketChannel _instance = WebSocketChannel._();

  WebSocketChannel._();

  factory WebSocketChannel() {
    return _instance;
  }

  late IOWebSocketChannel _channel;
  late WebSocketHelper _helper;

  initChannel(WebSocketHelper helper) {
    _helper = helper;
    _channel = IOWebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:45550/metaUni/webSocketAPI/ws'),
      headers: {'UUID': _helper.uuid, 'JWT': _helper.jwt},
    );
    _channel.stream.listen((event) {
      print("收到：$event");
      Map<dynamic,dynamic> map = jsonDecode(event);
      switch(map["type"]){
        case "NewCommonMessage":
          CommonMessage commonMessage = CommonMessage.fromJson(map["data"]);
          _helper.storeNewCommonMessage(commonMessage);
          _helper.commonMessageCubit.receive(commonMessage);
          break;
      }
    },onDone: (){
      print("掉线了");
    });
  }

  closeChannel() {
    _channel.sink.close();
  }
}
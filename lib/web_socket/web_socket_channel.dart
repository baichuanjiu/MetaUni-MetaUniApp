import 'package:web_socket_channel/io.dart';

//单例模式构建webSocket
class WebSocketChannel {
  static final WebSocketChannel _instance = WebSocketChannel._();

  WebSocketChannel._();

  factory WebSocketChannel() {
    return _instance;
  }

  IOWebSocketChannel? _channel;

  initChannel(int uuid, String jwt) {
    _channel = IOWebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:45555/ws'),
      headers: {'UUID': uuid, 'JWT': jwt},
    );
    _channel!.stream.listen((event) {
      print("收到：$event");
    },onDone: (){
      print("掉线了");
    });
  }

  closeChannel() {
    if (_channel != null) {
      _channel!.sink.close();
    }
  }
}
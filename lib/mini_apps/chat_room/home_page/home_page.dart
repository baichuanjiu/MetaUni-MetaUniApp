import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/mini_apps/chat_room/home_page/security_gate/security_gate_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../reusable_components/logout/logout.dart';
import '../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../mini_app_manager.dart';

class ChatRoomHomePage extends StatefulWidget {
  const ChatRoomHomePage({super.key});

  @override
  State<ChatRoomHomePage> createState() => _ChatRoomHomePageState();
}

class _ChatRoomHomePageState extends State<ChatRoomHomePage> {
  late List<ChatRoomInfo> chatRoomList = [];

  late Dio dio;

  late Future<dynamic> init;

  _init() async {
    await _initDio();
    await getChatRoomList();
  }

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  getChatRoomList() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    final uuid = prefs.getInt('uuid');

    chatRoomList = [];

    try {
      Response response;
      response = await dio.get(
        '/chatRoom/chatRoomList',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> dataList = response.data['data']['dataList'];
          for (var data in dataList) {
            chatRoomList.add(ChatRoomInfo.fromJson(data));
          }
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        default:
          if (mounted) {
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    init = _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("聊聊屋"),
      ),
      body: FutureBuilder(
        future: init,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            case ConnectionState.active:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            case ConnectionState.waiting:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            case ConnectionState.done:
              if (snapshot.hasError) {
                return const Center(
                  child: CupertinoActivityIndicator(),
                );
              }
              return RefreshIndicator(
                  onRefresh: () async {
                    await getChatRoomList();
                    setState(() {

                    });
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: chatRoomList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatRoomSecurityGatePage(
                                chatRoomName: chatRoomList[index].name,
                                chatRoomDisplayName: chatRoomList[index].displayName,
                              ),
                            ),
                          );
                        },
                        leading: Avatar(chatRoomList[index].avatar),
                        title: Text(chatRoomList[index].displayName),
                        subtitle: Text("${chatRoomList[index].onlineNumber} 人在线"),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_outlined,
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const Divider();
                    },
                  ));
            default:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
          }
        },
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String avatar;

  const Avatar(this.avatar, {super.key});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fadeInDuration: const Duration(milliseconds: 800),
      fadeOutDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => CircleAvatar(
        radius: 25,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const CupertinoActivityIndicator(),
      ),
      imageUrl: avatar,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 25,
        backgroundImage: imageProvider,
      ),
      errorWidget: (context, url, error) =>  CircleAvatar(
        radius: 25,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.error_outline),
      ),
    );
  }
}

class ChatRoomInfo {
  late String avatar;
  late String name;
  late String displayName;
  late int onlineNumber;

  ChatRoomInfo({required this.avatar, required this.name, required this.displayName, required this.onlineNumber});

  ChatRoomInfo.fromJson(Map<String, dynamic> map) {
    avatar = map['avatar'];
    name = map['name'];
    displayName = map['displayName'];
    onlineNumber = map['onlineNumber'];
  }
}

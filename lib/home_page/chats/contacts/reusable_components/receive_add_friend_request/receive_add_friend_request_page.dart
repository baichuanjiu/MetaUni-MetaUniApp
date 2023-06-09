import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta_uni_app/database/models/friend/friendship.dart';
import 'package:meta_uni_app/database/models/user/brief_user_information.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../../bloc/bloc_manager.dart';
import '../../../../../bloc/chat_list_tile/models/chat_list_tile_update_data.dart';
import '../../../../../database/database_manager.dart';
import '../../../../../database/models/chat/chat.dart';
import '../../../../../database/models/chat/common_chat_status.dart';
import '../../../../../database/models/friend/friends_group.dart';
import '../../../../../database/models/message/common_message.dart';
import '../../../../../database/models/user/user_sync_table.dart';
import '../../../../../models/dio_model.dart';
import '../../../../../reusable_components/logout/logout.dart';
import '../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../reusable_components/friends_group/choose_friends_group_page.dart';

class ReceiveAddFriendRequestPage extends StatefulWidget {
  const ReceiveAddFriendRequestPage({super.key});

  @override
  State<ReceiveAddFriendRequestPage> createState() => _ReceiveAddFriendRequestPageState();
}

class _ReceiveAddFriendRequestPageState extends State<ReceiveAddFriendRequestPage> {
  late Future<dynamic> init;

  final DioModel dioModel = DioModel();

  late List<AddFriendRequestDataForReceiverWithStatus> requestList = [];

  FocusNode remarkFocusNode = FocusNode();
  TextEditingController remarkController = TextEditingController();

  late Database database;
  late FriendsGroupProvider friendsGroupProvider;
  late FriendshipProvider friendshipProvider;
  late int currentChosenGroupId;
  late String currentChosenGroupName;

  _init() async {
    await getAddFriendRequest();

    database = await DatabaseManager().getDatabase;
    friendsGroupProvider = FriendsGroupProvider(database);
    friendshipProvider = FriendshipProvider(database);
    currentChosenGroupId = await friendsGroupProvider.getFirst();
    currentChosenGroupName = (await friendsGroupProvider.getName(currentChosenGroupId))!;

    setState(() {});
  }

  getAddFriendRequest() async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/userAPI/friendship/request',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        default:
          //Message:"成功获取所有未处理的好友请求"
          requestList = [];
          List<dynamic> dataList = response.data['data']['dataList'];
          for (var element in dataList) {
            requestList.add(
              AddFriendRequestDataForReceiverWithStatus(AddFriendRequestDataForReceiver.fromJson(element), "isPending"),
            );
          }
          BlocManager().hasUnreadAddFriendRequestCubit.update(false);
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  rejectAddFriendRequest(int requestId, int index) async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dioModel.dio.put(
        '/metaUni/userAPI/friendship/request/reject/$requestId',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
          //Message:"您正在尝试拒绝一个错误的添加好友请求"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        default:
          //Message:"您已成功拒绝该请求"
          if (mounted) {
            requestList[index].status = "rejected";
            setState(() {});
            getNormalSnackBar(context, response.data['message']);
          }
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  storeNewMessage(CommonMessage message, int uuid) async {
    await database.transaction((transaction) async {
      CommonMessageProviderWithTransaction commonMessageProviderWithTransaction = CommonMessageProviderWithTransaction(transaction);

      commonMessageProviderWithTransaction.insert(message);

      UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
      userSyncTableProviderWithTransaction.updateSequenceForCommonMessages(uuid, message.sequence);

      ChatProviderWithTransaction chatProviderWithTransaction = ChatProviderWithTransaction(transaction);
      CommonChatStatusProviderWithTransaction commonChatStatusProviderWithTransaction = CommonChatStatusProviderWithTransaction(transaction);

      int chatId = message.chatId;
      Chat? chat = await chatProviderWithTransaction.get(chatId);
      if (chat == null) {
        chatProviderWithTransaction.insert(
          Chat(
            id: chatId,
            uuid: uuid,
            targetId: message.receiverId,
            isWithOtherUser: true,
            numberOfUnreadMessages: 0,
            lastMessageId: message.id,
            updatedTime: message.createdTime,
          ),
        );
        commonChatStatusProviderWithTransaction.insert(
          CommonChatStatus(chatId: chatId, lastMessageBeReadSendByMe: null, readTime: null, updatedTime: message.createdTime),
        );
      } else {
        chatProviderWithTransaction.update({
          'isDeleted': 0,
          'lastMessageId': message.id,
          'updatedTime': message.createdTime.millisecondsSinceEpoch,
        }, chatId);
      }
    });
  }

  sendMessage(int targetId, String jwt, int uuid) async {
    try {
      Response response;
      response = await dioModel.dio.post(
        '/metaUni/messageAPI/commonMessage/text',
        data: {
          "receiverId": targetId,
          "messageText": "自动消息：我们已经是好友了",
        },
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
          //Message:"目标用户不存在"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        case 3:
          //Message:"服务器端发生错误"
          if (mounted) {
            getNetworkErrorSnackBar(context);
          }
          break;
        default:
          CommonMessage message = CommonMessage.fromJson(response.data['data']);
          storeNewMessage(message, uuid);
          BlocManager().chatListTileDataCubit.shouldUpdate(ChatListTileUpdateData(chatId: message.chatId));
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  agreeAddFriendRequest(int requestId, int index) async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dioModel.dio.put(
        '/metaUni/userAPI/friendship/request/agree/$requestId',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
        data: {
          'remark': remarkController.text.isEmpty ? null : remarkController.text,
          'friendsGroupId': currentChosenGroupId,
        },
      );
      switch (response.data['code']) {
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
          //Message:"您正在尝试同意一个错误的添加好友请求"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        case 3:
          //Message:"您正在尝试使用一个不存在的好友分组"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        case 4:
          //Message:"你们已经是好友了"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        default:
          //Message:"您已成功同意该请求"
          if (mounted) {
            requestList[index].status = "agreed";
            setState(() {});
            getNormalSnackBar(context, response.data['message']);
            friendshipProvider.insert(
              Friendship.fromJson(
                response.data["data"]["friendship"],
              ),
            );
            sendMessage(requestList[index].data.sender.uuid, jwt!, uuid!);
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
  void dispose() {
    remarkFocusNode.dispose();
    remarkController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("新朋友"),
      ),
      body: FutureBuilder(
        future: init,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return const CupertinoActivityIndicator();
            case ConnectionState.active:
              return const CupertinoActivityIndicator();
            case ConnectionState.waiting:
              return const CupertinoActivityIndicator();
            case ConnectionState.done:
              if (snapshot.hasError) {
                return const CupertinoActivityIndicator();
              }
              return Column(
                children: [
                  Expanded(
                    child: requestList.isEmpty
                        ? Center(
                            child: Text(
                              "没有收到新的添加好友请求呢！",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            itemCount: requestList.length,
                            itemBuilder: (BuildContext context, int index) {
                              return ListTile(
                                leading: Avatar(requestList[index].data.sender.avatar),
                                title: Text(requestList[index].data.sender.nickname),
                                subtitle: Text(requestList[index].data.message == null ? "对方留言：无" : "对方留言：${requestList[index].data.message!}"),
                                trailing: requestList[index].status == "isPending"
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              rejectAddFriendRequest(
                                                requestList[index].data.id,
                                                index,
                                              );
                                            },
                                            child: const Text("拒绝"),
                                          ),
                                          Container(
                                            width: 5,
                                          ),
                                          FilledButton.tonal(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                context: context,
                                                builder: (context) {
                                                  return StatefulBuilder(
                                                    builder: (context, setState) {
                                                      return Column(
                                                        children: [
                                                          Row(
                                                            mainAxisSize: MainAxisSize.max,
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Container(
                                                                height: 4,
                                                                width: 50,
                                                                margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                                                                decoration: BoxDecoration(
                                                                  color: Theme.of(context).colorScheme.outline,
                                                                  borderRadius: const BorderRadius.all(Radius.circular(2.0)),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          ListTile(
                                                            leading: Avatar(requestList[index].data.sender.avatar),
                                                            title: Text(requestList[index].data.sender.nickname),
                                                            subtitle: Text(requestList[index].data.message == null ? "对方留言：无" : "对方留言：${requestList[index].data.message!}"),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Container(
                                                                  height: 20,
                                                                ),
                                                                const Text("设置备注与分组："),
                                                                Container(
                                                                  height: 5,
                                                                ),
                                                                TextField(
                                                                  focusNode: remarkFocusNode,
                                                                  controller: remarkController,
                                                                  decoration: InputDecoration(
                                                                    border: const OutlineInputBorder(borderSide: BorderSide.none),
                                                                    contentPadding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                                                                    prefixIcon: Column(
                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                      children: [
                                                                        Container(
                                                                          padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                                                                          child: Text(
                                                                            "备注：",
                                                                            style: Theme.of(context).textTheme.bodyLarge,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  inputFormatters: [
                                                                    //只允许输入最多15个字符
                                                                    LengthLimitingTextInputFormatter(15),
                                                                  ],
                                                                  keyboardType: TextInputType.multiline,
                                                                  textInputAction: TextInputAction.done,
                                                                  onTapOutside: (value) {
                                                                    remarkFocusNode.unfocus();
                                                                  },
                                                                ),
                                                                ListTile(
                                                                  title: Text(
                                                                    currentChosenGroupName,
                                                                    style: Theme.of(context).textTheme.bodyLarge,
                                                                  ),
                                                                  trailing: const Icon(
                                                                    Icons.chevron_right_outlined,
                                                                  ),
                                                                  onTap: () {
                                                                    Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder: (context) => ChooseFriendsGroupPage(
                                                                          currentChosenGroupId: currentChosenGroupId,
                                                                        ),
                                                                      ),
                                                                    ).then(
                                                                      (value) async {
                                                                        if (value != null) {
                                                                          currentChosenGroupId = value[0];
                                                                          currentChosenGroupName = (await friendsGroupProvider.getName(currentChosenGroupId))!;
                                                                          setState(() {});
                                                                        }
                                                                      },
                                                                    );
                                                                  },
                                                                ),
                                                                Container(
                                                                  height: 20,
                                                                ),
                                                                Row(
                                                                  mainAxisSize: MainAxisSize.max,
                                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                  children: [
                                                                    FilledButton.tonal(
                                                                      onPressed: () {
                                                                        Navigator.pop(context);
                                                                      },
                                                                      child: const Text("取消"),
                                                                    ),
                                                                    FilledButton(
                                                                      onPressed: () {
                                                                        agreeAddFriendRequest(
                                                                          requestList[index].data.id,
                                                                          index,
                                                                        );
                                                                        Navigator.pop(context);
                                                                      },
                                                                      child: const Text("确定"),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                              );
                                            },
                                            child: const Text("同意"),
                                          ),
                                        ],
                                      )
                                    : requestList[index].status == "rejected"
                                        ? Text(
                                            "已拒绝",
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          )
                                        : Text(
                                            "已同意",
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                onTap: () {
                                  Navigator.pushNamed(context, '/user/profile', arguments: requestList[index].data.sender.uuid);
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            default:
              return const CupertinoActivityIndicator();
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
      placeholder: (context, url) => const CupertinoActivityIndicator(),
      imageUrl: avatar,
      imageBuilder: (context, imageProvider) => SizedBox(
        width: 45,
        height: 45,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image(
            image: imageProvider,
          ),
        ),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.error_outline),
    );
  }
}

class AddFriendRequestDataForReceiver {
  late int id;
  late BriefUserInformation sender;
  late String? message;

  AddFriendRequestDataForReceiver.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    sender = BriefUserInformation.fromJson(map['sender']);
    message = map['message'];
  }
}

class AddFriendRequestDataForReceiverWithStatus {
  late AddFriendRequestDataForReceiver data;
  late String status;

  AddFriendRequestDataForReceiverWithStatus(this.data, this.status);
}

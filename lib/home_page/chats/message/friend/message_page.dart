import 'dart:ui';
import 'package:http_parser/http_parser.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_uni_app/bloc/chat_target_information/chat_target_information_bloc.dart';
import 'package:meta_uni_app/bloc/chat_target_information/models/chat_target_information_update_data.dart';
import 'package:meta_uni_app/bloc/message/common_chat_status_bloc.dart';
import 'package:meta_uni_app/bloc/message/common_message_bloc.dart';
import 'package:meta_uni_app/database/models/user/user_sync_table.dart';
import 'package:meta_uni_app/home_page/chats/message/friend/models/message_input_data.dart';
import 'package:meta_uni_app/reusable_components/get_current_user_information/get_current_user_information.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:video_compress/video_compress.dart';
import '../../../../bloc/bloc_manager.dart';
import '../../../../bloc/chat_list_tile/models/chat_list_tile_update_data.dart';
import '../../../../bloc/message/common_message_be_recalled.dart';
import '../../../../bloc/message/total_number_of_unread_messages_bloc.dart';
import '../../../../database/database_manager.dart';
import '../../../../database/models/chat/chat.dart';
import '../../../../database/models/chat/common_chat_status.dart';
import '../../../../database/models/message/common_message.dart';
import '../../../../database/models/user/brief_user_information.dart';
import '../../../../models/dio_model.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../web_socket/web_socket_channel.dart';
import '../../chat_list_tile/models/brief_chat_target_information.dart';
import 'bubble/bubble.dart';
import 'bubble/bubble_helper.dart';
import 'message_input_field/message_input_field.dart';

class FriendMessagePage extends StatefulWidget {
  const FriendMessagePage({super.key});

  @override
  State<FriendMessagePage> createState() => _FriendMessagePageState();
}

class _FriendMessagePageState extends State<FriendMessagePage> with TickerProviderStateMixin {
  EditableTextState? editableTextState;
  late CommonMessageBubbleHelper bubbleHelper = CommonMessageBubbleHelper(setEditableTextState, removeContextMenu);

  late Future<dynamic> init;
  late int uuid;
  late String jwt;

  final DioModel dioModel = DioModel();

  late Database database;

  late BriefUserInformation me;

  _init() async {
    final prefs = await SharedPreferences.getInstance();

    uuid = prefs.getInt('uuid')!;
    jwt = prefs.getString('jwt')!;

    database = await DatabaseManager().getDatabase;

    me = await getCurrentUserInformation();
  }

  void setEditableTextState(EditableTextState? editableTextState) {
    this.editableTextState = editableTextState;
  }

  void removeContextMenu() {
    if (editableTextState != null) {
      editableTextState!.userUpdateTextEditingValue(
        editableTextState!.textEditingValue.copyWith(
          selection: const TextSelection(baseOffset: 0, extentOffset: 0),
        ),
        SelectionChangedCause.tap,
      );
    }
    ContextMenuController.removeAny();
  }

  late BriefChatTargetInformation chatTargetInformation;
  late BriefUserInformation targetUserInformation;
  late int totalNumberOfUnreadMessages = 0;
  late int numberOfUnreadMessagesInChat = 0;

  late List<CommonMessage> historyMessages = [];

  late List<CommonMessage> newMessages = [];

  late int historyMessagesMaxId = -1;

  late CommonChatStatus commonChatStatus;

  int unreadMessageNumber = 0;

  CommonMessageBubbleReadonly? messageRepliedBubble;
  int? messageReplied;
  late AnimationController replyModeAnimationController;
  late Animation<double> replyModeAnimation;

  toggleToReplyMode(bool isSentByMe, BriefUserInformation sender, CommonMessage message, bool isRead, DateTime? readTime) {
    messageRepliedBubble = CommonMessageBubbleReadonly(
      isSentByMe: isSentByMe,
      sender: sender,
      message: message,
      isRead: isRead,
      readTime: readTime,
    );
    setState(() {
      messageReplied = message.id;
    });
    replyModeAnimationController.forward();
  }

  void sendMessage(MessageInputData inputData) async {
    Map<String, dynamic> formDataMap = {
      'receiverId': targetUserInformation.uuid,
      'messageReplied': messageReplied,
      'messageText': inputData.messageText,
    };

    for (int i = 0; i < inputData.messageMedias.length; i++) {
      List<String> mimeType = lookupMimeType(inputData.messageMedias[i].path)!.split('/');
      if (mimeType[0] == 'image') {
        var decodedImage = await decodeImageFromList(
          inputData.messageMedias[i].readAsBytesSync(),
        );
        final newEntries = {
          'messageMedias[$i].File': await MultipartFile.fromFile(
            inputData.messageMedias[i].path,
            contentType: MediaType(
              mimeType[0],
              mimeType[1],
            ),
          ),
          'messageMedias[$i].AspectRatio': decodedImage.width / decodedImage.height,
        };
        formDataMap.addEntries(newEntries.entries);
      } else if (mimeType[0] == 'video') {
        File thumbnailFile = await VideoCompress.getFileThumbnail(
          inputData.messageMedias[i].path,
        );
        MediaInfo mediaInfo = await VideoCompress.getMediaInfo(inputData.messageMedias[i].path);
        final newEntries = {
          'messageMedias[$i].File': await MultipartFile.fromFile(
            inputData.messageMedias[i].path,
            contentType: MediaType(
              mimeType[0],
              mimeType[1],
            ),
          ),
          'messageMedias[$i].AspectRatio': mediaInfo.height! / mediaInfo.width!,
          'messageMedias[$i].PreviewImage': await MultipartFile.fromFile(
            thumbnailFile.path,
            contentType: MediaType(
              'image',
              'jpeg',
            ),
          ),
          'messageMedias[$i].TimeTotal': mediaInfo.duration!.toInt(),
        };
        formDataMap.addEntries(newEntries.entries);
      }
    }

    try {
      Response response;
      var formData = FormData.fromMap(
        formDataMap,
        ListFormat.multiCompatible,
      );
      response = await dioModel.dio.post(
        '/metaUni/messageAPI/commonMessage/common',
        data: formData,
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          if (messageReplied != null) {
            replyModeAnimationController.reverse().then((value) {
              setState(() {
                messageRepliedBubble = null;
                messageReplied = null;
              });
            });
          }
          CommonMessage message = CommonMessage.fromJson(response.data['data']);
          await storeNewMessage(message);
          BlocManager().chatListTileDataCubit.shouldUpdate(
                ChatListTileUpdateData(
                  chatId: message.chatId,
                ),
              );
          setState(() {
            newMessages.add(message);
          });
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            _scrollController.animateTo(_scrollController.position.minScrollExtent, duration: const Duration(seconds: 1), curve: Curves.fastOutSlowIn);
          });
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
        //Message:"目标用户不存在"
        case 3:
        //Message:"您正在尝试回复一条不属于该对话的消息"
        case 4:
        //Message:"发送消息失败，文字内容与媒体文件内容不能同时为空"
        case 5:
        //Message:"发送消息失败，上传媒体文件数超过限制"
        case 6:
        //Message:"发送消息失败，禁止上传规定格式以外的文件"
        case 7:
          //Message:"发送消息失败，您已被对方屏蔽"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        case 8:
        //Message:"发生错误，消息发送失败"
        case 9:
          //Message:"发生错误，消息发送失败"
          if (mounted) {
            getNetworkErrorSnackBar(context);
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

  storeNewMessage(CommonMessage message) async {
    await database.transaction((transaction) async {
      CommonMessageProviderWithTransaction commonMessageProviderWithTransaction = CommonMessageProviderWithTransaction(transaction);

      commonMessageProviderWithTransaction.insert(message);

      UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
      userSyncTableProviderWithTransaction.updateSequenceForCommonMessages(uuid, message.sequence);
      userSyncTableProviderWithTransaction.update({
        'updatedTimeForChats': message.createdTime.millisecondsSinceEpoch,
      }, uuid);

      ChatProviderWithTransaction chatProviderWithTransaction = ChatProviderWithTransaction(transaction);
      CommonChatStatusProviderWithTransaction commonChatStatusProviderWithTransaction = CommonChatStatusProviderWithTransaction(transaction);

      int chatId = message.chatId;
      Chat? chat = await chatProviderWithTransaction.get(chatId);
      if (chat == null) {
        chatProviderWithTransaction.insert(
          Chat(
            id: chatId,
            uuid: uuid,
            targetId: chatTargetInformation.id,
            isWithOtherUser: true,
            numberOfUnreadMessages: 0,
            lastMessageId: message.id,
            updatedTime: message.createdTime,
          ),
        );
        commonChatStatusProviderWithTransaction.insert(
          CommonChatStatus(chatId: chatId, lastMessageBeReadSendByMe: null, readTime: null, updatedTime: message.createdTime),
        );
        chatTargetInformation.chatId = chatId;
        commonChatStatus = (await commonChatStatusProviderWithTransaction.get(chatTargetInformation.chatId!))!;
      } else {
        chatProviderWithTransaction.update({
          'isDeleted': 0,
          'lastMessageId': message.id,
          'updatedTime': message.createdTime.millisecondsSinceEpoch,
        }, chatId);
      }
    });
  }

  void receiveNewMessage(CommonMessage message) {
    setState(() {
      newMessages.add(message);
    });
    if (_scrollController.position.extentBefore < MediaQuery.of(context).size.height) {
      WebSocketChannel().sendReadCommonMessagesRequestData(chatTargetInformation.chatId!);
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        _scrollController.animateTo(_scrollController.position.minScrollExtent, duration: const Duration(seconds: 1), curve: Curves.fastOutSlowIn);
      });
    } else {
      setState(() {
        unreadMessageNumber++;
      });
    }
  }

  final ScrollController _scrollController = ScrollController();

  int? lastId;
  bool isLoading = false;
  bool hasMore = true;
  late CommonMessageProvider commonMessageProvider = CommonMessageProvider(database);

  _loadHistoryMessages() async {
    isLoading = true;
    hasMore = false;

    int loadCount = 20;
    var dataList = await commonMessageProvider.getHistoryMessagesNotDeletedOrderByIdByLastId(chatTargetInformation.chatId!, lastId, loadCount);
    if (dataList.isNotEmpty) {
      lastId = dataList.last.id;
    }
    if (dataList.length < loadCount) {
      hasMore = false;
    }
    else
    {
      hasMore = true;
    }
    historyMessages.addAll(dataList);

    setState(() {});
    isLoading = false;
  }

  @override
  void initState() {
    super.initState();

    init = _init();

    replyModeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    replyModeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: replyModeAnimationController, curve: Curves.ease),
    );

    _scrollController.addListener(() {
      if (unreadMessageNumber > 0 && _scrollController.position.extentBefore < MediaQuery.of(context).size.height) {
        WebSocketChannel().sendReadCommonMessagesRequestData(chatTargetInformation.chatId!);
        setState(() {
          unreadMessageNumber = 0;
        });
      }
      if (chatTargetInformation.chatId != null && _scrollController.position.extentAfter < 300 && !isLoading && hasMore) {
        isLoading = true;
        _loadHistoryMessages();
      }
    });
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    chatTargetInformation = ModalRoute.of(context)!.settings.arguments as BriefChatTargetInformation;
    database = await DatabaseManager().getDatabase;
    targetUserInformation =
        BriefUserInformation(uuid: chatTargetInformation.id, avatar: chatTargetInformation.avatar, nickname: chatTargetInformation.name, updatedTime: chatTargetInformation.updatedTime);

    ChatProvider chatProvider = ChatProvider(database);
    chatTargetInformation.chatId ??= await (chatProvider.getWithUserNotDeleted(chatTargetInformation.id));

    totalNumberOfUnreadMessages = BlocManager().totalNumberOfUnreadMessagesCubit.get();
    if (chatTargetInformation.chatId != null) {
      numberOfUnreadMessagesInChat = await chatProvider.getNumberOfUnreadMessages(chatTargetInformation.chatId!);
      if (numberOfUnreadMessagesInChat > 0) {
        WebSocketChannel().sendReadCommonMessagesRequestData(chatTargetInformation.chatId!);
      }

      await _loadHistoryMessages();
      if (historyMessages.isNotEmpty) {
        historyMessagesMaxId = historyMessages[0].id;
      }

      CommonChatStatusProvider commonChatStatusProvider = CommonChatStatusProvider(database);
      commonChatStatus = (await commonChatStatusProvider.get(chatTargetInformation.chatId!))!;

      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    replyModeAnimationController.dispose();

    super.dispose();
  }

  Key centerKey = const Key("centerKey");

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CommonMessageCubit>.value(value: BlocManager().commonMessageCubit),
        BlocProvider<CommonMessageBeRecalledCubit>.value(value: BlocManager().commonMessageBeRecalledCubit),
        BlocProvider<TotalNumberOfUnreadMessagesCubit>.value(value: BlocManager().totalNumberOfUnreadMessagesCubit),
        BlocProvider<CommonChatStatusCubit>.value(value: BlocManager().commonChatStatusCubit),
        BlocProvider<ChatTargetInformationCubit>.value(value: BlocManager().chatTargetInformationCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<CommonMessageCubit, CommonMessage?>(
            listener: (context, commonMessage) async {
              if (chatTargetInformation.chatId != null) {
                if (commonMessage!.chatId == chatTargetInformation.chatId) {
                  receiveNewMessage(commonMessage);
                }
              } else if (chatTargetInformation.id == commonMessage!.senderId) {
                chatTargetInformation.chatId = commonMessage.chatId;
                CommonChatStatusProvider commonChatStatusProvider = CommonChatStatusProvider(database);
                commonChatStatus = (await commonChatStatusProvider.get(chatTargetInformation.chatId!))!;
                receiveNewMessage(commonMessage);
              }
            },
          ),
          BlocListener<CommonMessageBeRecalledCubit, CommonMessage?>(
            listener: (context, commonMessage) async {
              if (commonMessage!.chatId == chatTargetInformation.chatId) {
                if (commonMessage.id <= historyMessagesMaxId) {
                  int index = historyMessages.indexWhere((element) => element.id == commonMessage.id);
                  if (index != -1) {
                    setState(() {
                      historyMessages[index].isRecalled = true;
                    });
                  }
                } else {
                  int index = newMessages.indexWhere((element) => element.id == commonMessage.id);
                  if (index != -1) {
                    setState(() {
                      newMessages[index].isRecalled = true;
                    });
                  }
                }
              }
            },
          ),
          BlocListener<TotalNumberOfUnreadMessagesCubit, int?>(
            listener: (context, number) async {
              if (chatTargetInformation.chatId != null) {
                ChatProvider chatProvider = ChatProvider(database);
                numberOfUnreadMessagesInChat = await chatProvider.getNumberOfUnreadMessages(chatTargetInformation.chatId!);
                totalNumberOfUnreadMessages = number!;
              }
            },
          ),
          BlocListener<CommonChatStatusCubit, CommonChatStatus?>(
            listener: (context, newStatus) {
              if (chatTargetInformation.chatId != null) {
                if (newStatus!.chatId == chatTargetInformation.chatId!) {
                  commonChatStatus = newStatus;
                  setState(() {});
                }
              }
            },
          ),
          BlocListener<ChatTargetInformationCubit, ChatTargetInformationUpdateData?>(
            listener: (context, newStatus) {
              if (chatTargetInformation.chatId != null && chatTargetInformation.chatId == newStatus!.chatId) {
                setState(() {
                  chatTargetInformation.name = newStatus.name;
                });
              }
            },
          ),
        ],
        child: WillPopScope(
          onWillPop: () async {
            bubbleHelper.removeContextMenu();
            Navigator.of(context).pop();
            return true;
          },
          child: GestureDetector(
            onLongPressDown: (details) {
              if (editableTextState == null) {
                ContextMenuController.removeAny();
              }
            },
            onTap: () {
              bubbleHelper.removeContextMenu();
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(chatTargetInformation.name),
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: totalNumberOfUnreadMessages - numberOfUnreadMessagesInChat == 0
                      ? const Icon(Icons.arrow_back_ios_new_outlined)
                      : Badge(
                          label: Text(totalNumberOfUnreadMessages - numberOfUnreadMessagesInChat > 99 ? "99+" : (totalNumberOfUnreadMessages - numberOfUnreadMessagesInChat).toString()),
                          child: const Icon(Icons.arrow_back_ios_new_outlined),
                        ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      bubbleHelper.removeContextMenu();
                      Navigator.pushNamed(context, '/user/profile/routeFromFriendMessagePage', arguments: chatTargetInformation.id);
                    },
                    icon: const Icon(Icons.menu_outlined),
                  ),
                ],
              ),
              body: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FutureBuilder(
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
                              return Stack(
                                children: [
                                  CustomScrollView(
                                    controller: _scrollController,
                                    reverse: true,
                                    center: centerKey,
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    slivers: [
                                      SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            bool isSentByMe;
                                            if (newMessages[index].senderId == uuid) {
                                              isSentByMe = true;
                                            } else {
                                              isSentByMe = false;
                                            }
                                            if (commonChatStatus.lastMessageBeReadSendByMe != null && commonChatStatus.lastMessageBeReadSendByMe! > historyMessagesMaxId) {
                                              if (commonChatStatus.lastMessageBeReadSendByMe == newMessages[index].id) {
                                                return CommonMessageBubble(
                                                  isSentByMe: isSentByMe,
                                                  bubbleHelper: bubbleHelper,
                                                  sender: isSentByMe ? me : targetUserInformation,
                                                  message: newMessages[index],
                                                  isRead: true,
                                                  readTime: commonChatStatus.readTime!,
                                                  onReply: toggleToReplyMode,
                                                );
                                              }
                                            }
                                            return CommonMessageBubble(
                                              isSentByMe: isSentByMe,
                                              bubbleHelper: bubbleHelper,
                                              sender: isSentByMe ? me : targetUserInformation,
                                              message: newMessages[index],
                                              onReply: toggleToReplyMode,
                                            );
                                          },
                                          childCount: newMessages.length,
                                        ),
                                      ),
                                      SliverPadding(
                                        padding: EdgeInsets.zero,
                                        key: centerKey,
                                      ),
                                      SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            bool isSentByMe;
                                            if (historyMessages[index].senderId == uuid) {
                                              isSentByMe = true;
                                            } else {
                                              isSentByMe = false;
                                            }
                                            if (commonChatStatus.lastMessageBeReadSendByMe != null && commonChatStatus.lastMessageBeReadSendByMe! <= historyMessagesMaxId) {
                                              if (commonChatStatus.lastMessageBeReadSendByMe == historyMessages[index].id) {
                                                return CommonMessageBubble(
                                                  isSentByMe: isSentByMe,
                                                  bubbleHelper: bubbleHelper,
                                                  sender: isSentByMe ? me : targetUserInformation,
                                                  message: historyMessages[index],
                                                  isRead: true,
                                                  readTime: commonChatStatus.readTime!,
                                                  onReply: toggleToReplyMode,
                                                );
                                              }
                                            }
                                            return CommonMessageBubble(
                                              isSentByMe: isSentByMe,
                                              bubbleHelper: bubbleHelper,
                                              sender: isSentByMe ? me : targetUserInformation,
                                              message: historyMessages[index],
                                              onReply: toggleToReplyMode,
                                            );
                                          },
                                          childCount: historyMessages.length,
                                        ),
                                      ),
                                    ],
                                  ),
                                  unreadMessageNumber == 0
                                      ? Container()
                                      : Positioned(
                                          right: 15,
                                          bottom: 15,
                                          child: GestureDetector(
                                            onTap: () {
                                              _scrollController.animateTo(_scrollController.position.minScrollExtent, duration: const Duration(seconds: 1), curve: Curves.fastOutSlowIn);
                                            },
                                            child: CircleAvatar(
                                              radius: 15,
                                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                              child: Text(
                                                unreadMessageNumber > 99 ? "99+" : unreadMessageNumber.toString(),
                                                style: Theme.of(context).textTheme.bodyMedium?.apply(
                                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                  messageReplied == null
                                      ? Container()
                                      : SizeTransition(
                                          sizeFactor: replyModeAnimation,
                                          axis: Axis.vertical,
                                          axisAlignment: 1.0,
                                          child: GestureDetector(
                                            onTap: () {
                                              replyModeAnimationController.reverse().then((value) {
                                                setState(() {
                                                  messageRepliedBubble = null;
                                                  messageReplied = null;
                                                });
                                              });
                                            },
                                            child: Stack(
                                              children: [
                                                BackdropFilter(
                                                  filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                                                  child: Container(),
                                                ),
                                                Positioned.fill(
                                                  child: SingleChildScrollView(
                                                    physics: const AlwaysScrollableScrollPhysics(
                                                      parent: BouncingScrollPhysics(),
                                                    ),
                                                    reverse: true,
                                                    child: messageRepliedBubble!,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ],
                              );
                            default:
                              return const CupertinoActivityIndicator();
                          }
                        },
                      ),
                    ),
                    MessageInputField(
                      removeContextMenu: bubbleHelper.removeContextMenu,
                      sendMessage: sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

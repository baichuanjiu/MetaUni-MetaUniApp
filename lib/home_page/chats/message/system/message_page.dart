import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../bloc/bloc_manager.dart';
import '../../../../bloc/message/system_message_bloc.dart';
import '../../../../bloc/message/total_number_of_unread_messages_bloc.dart';
import '../../../../database/database_manager.dart';
import '../../../../database/models/chat/chat.dart';
import '../../../../database/models/message/system_message.dart';
import '../../../../database/models/user/user_sync_table.dart';
import '../../../../models/dio_model.dart';
import '../../../../reusable_components/get_current_user_information/get_current_user_information.dart';
import '../../../../web_socket/web_socket_channel.dart';
import '../../chat_list_tile/models/brief_chat_target_information.dart';
import 'bubble/bubble.dart';
import 'bubble/bubble_helper.dart';
import 'models/sender.dart';

class SystemMessagePage extends StatefulWidget {
  const SystemMessagePage({super.key});

  @override
  State<SystemMessagePage> createState() => _SystemMessagePageState();
}

class _SystemMessagePageState extends State<SystemMessagePage> with TickerProviderStateMixin {
  EditableTextState? editableTextState;
  late SystemMessageBubbleHelper bubbleHelper = SystemMessageBubbleHelper(setEditableTextState, removeContextMenu);

  late Future<dynamic> init;
  late int uuid;
  late String jwt;

  final DioModel dioModel = DioModel();

  late Database database;

  late Sender me;

  _init() async {
    final prefs = await SharedPreferences.getInstance();

    uuid = prefs.getInt('uuid')!;
    jwt = prefs.getString('jwt')!;

    database = await DatabaseManager().getDatabase;

    var briefUserInfo = await getCurrentUserInformation();
    me = Sender(uuid: briefUserInfo.uuid, isSystem: false, avatar: briefUserInfo.avatar, name: briefUserInfo.nickname);
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
  late Sender targetSystemInformation;
  late int totalNumberOfUnreadMessages = 0;
  late int numberOfUnreadMessagesInChat = 0;

  late List<SystemMessage> historyMessages = [];

  late List<SystemMessage> newMessages = [];

  late int historyMessagesMaxId = -1;

  int unreadMessageNumber = 0;

  storeNewMessage(SystemMessage message) async {
    await database.transaction((transaction) async {
      SystemMessageProviderWithTransaction systemMessageProviderWithTransaction = SystemMessageProviderWithTransaction(transaction);

      systemMessageProviderWithTransaction.insert(message);

      UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
      userSyncTableProviderWithTransaction.updateSequenceForSystemMessages(uuid, message.sequence);
      userSyncTableProviderWithTransaction.update({
        'updatedTimeForChats': message.createdTime.millisecondsSinceEpoch,
      }, uuid);

      ChatProviderWithTransaction chatProviderWithTransaction = ChatProviderWithTransaction(transaction);

      int chatId = message.chatId;
      Chat? chat = await chatProviderWithTransaction.get(chatId);
      if (chat == null) {
        chatProviderWithTransaction.insert(
          Chat(
            id: chatId,
            uuid: uuid,
            targetId: chatTargetInformation.id,
            isWithSystem: true,
            numberOfUnreadMessages: 0,
            lastMessageId: message.id,
            updatedTime: message.createdTime,
          ),
        );
        chatTargetInformation.chatId = chatId;
      } else {
        chatProviderWithTransaction.update({
          'isDeleted': 0,
          'lastMessageId': message.id,
          'updatedTime': message.createdTime.millisecondsSinceEpoch,
        }, chatId);
      }
    });
  }

  void receiveNewMessage(SystemMessage message) {
    setState(() {
      newMessages.add(message);
    });
    if (_scrollController.position.extentBefore < MediaQuery.of(context).size.height) {
      WebSocketChannel().sendReadSystemMessagesRequestData(chatTargetInformation.chatId!);
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
  late SystemMessageProvider systemMessageProvider = SystemMessageProvider(database);

  _loadHistoryMessages() async {
    isLoading = true;
    hasMore = false;

    int loadCount = 20;
    var dataList = await systemMessageProvider.getHistoryMessagesNotDeletedOrderByIdByLastId(chatTargetInformation.chatId!, lastId, loadCount);
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

    _scrollController.addListener(() {
      if (unreadMessageNumber > 0 && _scrollController.position.extentBefore < MediaQuery.of(context).size.height) {
        WebSocketChannel().sendReadSystemMessagesRequestData(chatTargetInformation.chatId!);
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
    targetSystemInformation =
        Sender(uuid: chatTargetInformation.id,isSystem: true, avatar: chatTargetInformation.avatar, name: chatTargetInformation.name,);

    ChatProvider chatProvider = ChatProvider(database);
    chatTargetInformation.chatId ??= await (chatProvider.getWithUserNotDeleted(chatTargetInformation.id));

    totalNumberOfUnreadMessages = BlocManager().totalNumberOfUnreadMessagesCubit.get();
    if (chatTargetInformation.chatId != null) {
      numberOfUnreadMessagesInChat = await chatProvider.getNumberOfUnreadMessages(chatTargetInformation.chatId!);
      if (numberOfUnreadMessagesInChat > 0) {
        WebSocketChannel().sendReadSystemMessagesRequestData(chatTargetInformation.chatId!);
      }

      await _loadHistoryMessages();
      if (historyMessages.isNotEmpty) {
        historyMessagesMaxId = historyMessages[0].id;
      }

      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  Key centerKey = const Key("centerKey");


  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SystemMessageCubit>.value(value: BlocManager().systemMessageCubit),
        BlocProvider<TotalNumberOfUnreadMessagesCubit>.value(value: BlocManager().totalNumberOfUnreadMessagesCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<SystemMessageCubit, SystemMessage?>(
            listener: (context, systemMessage) async {
              if (chatTargetInformation.chatId != null) {
                if (systemMessage!.chatId == chatTargetInformation.chatId) {
                  receiveNewMessage(systemMessage);
                }
              } else if (chatTargetInformation.id == systemMessage!.senderId) {
                chatTargetInformation.chatId = systemMessage.chatId;
                receiveNewMessage(systemMessage);
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
                                            return SystemMessageBubble(
                                              isSentByMe: isSentByMe,
                                              bubbleHelper: bubbleHelper,
                                              sender: isSentByMe ? me : targetSystemInformation,
                                              message: newMessages[index],
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
                                            return SystemMessageBubble(
                                              isSentByMe: isSentByMe,
                                              bubbleHelper: bubbleHelper,
                                              sender: isSentByMe ? me : targetSystemInformation,
                                              message: historyMessages[index],
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
                                ],
                              );
                            default:
                              return const CupertinoActivityIndicator();
                          }
                        },
                      ),
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
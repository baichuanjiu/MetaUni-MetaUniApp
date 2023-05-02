import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta_uni_app/bloc/message/common_message_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../bloc/bloc_manager.dart';
import '../../../../database/database_manager.dart';
import '../../../../database/models/chat/chat.dart';
import '../../../../database/models/message/common_message.dart';
import '../../../../database/models/user/brief_user_information.dart';
import '../../../../models/dio_model.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../chat_list_tile/models/brief_chat_target_information.dart';
import 'bubble/bubble.dart';
import 'bubble/bubble_helper.dart';

class FriendMessagePage extends StatefulWidget {
  const FriendMessagePage({super.key});

  @override
  State<FriendMessagePage> createState() => _FriendMessagePageState();
}

class _FriendMessagePageState extends State<FriendMessagePage> {
  EditableTextState? editableTextState;
  late CommonMessageBubbleHelper bubbleHelper = CommonMessageBubbleHelper(setEditableTextState, removeContextMenu);

  //后续要修改
  late Future<dynamic> init;
  late int uuid;
  late String jwt;

  final DioModel dioModel = DioModel();

  late Database database;

  late BriefUserInformation me;

  //后续要修改
  _init() async {
    final prefs = await SharedPreferences.getInstance();

    uuid = prefs.getInt('uuid')!;
    jwt = prefs.getString('jwt')!;

    database = await DatabaseManager().getDatabase;

    BriefUserInformationProvider briefUserInformationProvider = BriefUserInformationProvider(database);
    me = (await briefUserInformationProvider.get(uuid))!;
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

  //后面改成从数据库读取
  late List<CommonMessage> historyMessages = [];

  late List<CommonMessage> newMessages = [];

  void sendMessage(CommonMessageSendData sendData) async {
    if (sendData.isTextMessage) {
      try {
        Response response;
        response = await dioModel.dio.post(
          '/metaUni/messageAPI/commonMessage/text',
          data: {
            "receiverId": sendData.receiverId,
            "messageText": sendData.messageText,
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
            storeNewMessage(message);
            setState(() {
              newMessages.add(message);
            });
            SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
              _scrollController.animateTo(_scrollController.position.minScrollExtent, duration: const Duration(seconds: 1), curve: Curves.fastOutSlowIn);
            });
        }
      } catch (e) {
        if (mounted) {
          getNetworkErrorSnackBar(context);
        }
      }
    }
  }

  void storeNewMessage(CommonMessage message) async {
    await database.transaction((transaction) async {
      CommonMessageProviderWithTransaction commonMessageProviderWithTransaction = CommonMessageProviderWithTransaction(transaction);

      commonMessageProviderWithTransaction.insert(message);

      ChatProviderWithTransaction chatProviderWithTransaction = ChatProviderWithTransaction(transaction);

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
    if (_scrollController.position.extentBefore < 1) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        _scrollController.animateTo(_scrollController.position.minScrollExtent, duration: const Duration(seconds: 1), curve: Curves.fastOutSlowIn);
      });
    }
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    //后续要修改
    init = _init();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    chatTargetInformation = ModalRoute.of(context)!.settings.arguments as BriefChatTargetInformation;
    BriefUserInformationProvider briefUserInformationProvider = BriefUserInformationProvider(await DatabaseManager().getDatabase);
    targetUserInformation = (await briefUserInformationProvider.get(chatTargetInformation.id))!;

    //后续要修改 比如每次只获取X条，而并不是一次性全获取
    CommonMessageProvider commonMessageProvider = CommonMessageProvider(database);
    historyMessages = (await commonMessageProvider.getAllNotDeletedInChat(chatTargetInformation.chatId!)).reversed.toList();
    setState(() {

    });
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
        BlocProvider<CommonMessageCubit>.value(value: BlocManager().commonMessageCubit),
      ],
      child: MultiBlocListener(
          listeners: [
            BlocListener<CommonMessageCubit, CommonMessage?>(
              listener: (context, commonMessage) {
                //后续还要修改，首先得判断是不是此Chat下的消息
                receiveNewMessage(commonMessage!);
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
                    icon: const Icon(Icons.arrow_back_ios_new_outlined),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () {
                        bubbleHelper.removeContextMenu();
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
                            //后续可能要修改
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
                                  return CustomScrollView(
                                    controller: _scrollController,
                                    reverse: true,
                                    center: centerKey,
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    slivers: [
                                      // SliverToBoxAdapter(
                                      //   child: Text("新发送的消息"),
                                      // ),
                                      SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            bool isSentByMe;
                                            if (newMessages[index].senderId == uuid) {
                                              isSentByMe = true;
                                            } else {
                                              isSentByMe = false;
                                            }
                                            return CommonMessageBubble(
                                              isSentByMe: isSentByMe,
                                              bubbleHelper: bubbleHelper,
                                              sender: isSentByMe ? me : targetUserInformation,
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
                                            return CommonMessageBubble(
                                              isSentByMe: isSentByMe,
                                              bubbleHelper: bubbleHelper,
                                              sender: isSentByMe ? me : targetUserInformation,
                                              message: historyMessages[index],
                                            );
                                          },
                                          childCount: historyMessages.length,
                                        ),
                                      ),
                                    ],
                                  );
                                default:
                                  return const CupertinoActivityIndicator();
                              }
                            }),
                      ),
                      MessageInputField(
                        receiverId: chatTargetInformation.id,
                        removeContextMenu: bubbleHelper.removeContextMenu,
                        sendMessage: sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )),
    );
  }
}

class MessageInputField extends StatefulWidget {
  final int receiverId;
  final void Function() removeContextMenu;
  final void Function(CommonMessageSendData) sendMessage;

  const MessageInputField({super.key, required this.receiverId, required this.removeContextMenu, required this.sendMessage});

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  FocusNode messageTextFocusNode = FocusNode();
  TextEditingController messageTextController = TextEditingController();
  IconButton? _suffixIcon;
  late IconButton micButton = IconButton(
    onPressed: () {
      widget.removeContextMenu();
    },
    icon: Icon(
      Icons.mic_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _suffixIcon = micButton;
  }

  @override
  void dispose() {
    messageTextFocusNode.dispose();
    messageTextController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 100,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              widget.removeContextMenu();
            },
            icon: Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: () {
              widget.removeContextMenu();
            },
            icon: Icon(
              Icons.image_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: TextField(
              focusNode: messageTextFocusNode,
              controller: messageTextController,
              decoration: InputDecoration(
                filled: true,
                border: const OutlineInputBorder(borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                suffixIcon: _suffixIcon,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              onTap: () {
                widget.removeContextMenu();
              },
              onTapOutside: (value) {
                messageTextFocusNode.unfocus();
              },
              onChanged: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _suffixIcon = IconButton(
                      onPressed: () {
                        //后续做调整
                        widget.sendMessage(CommonMessageSendData(
                          receiverId: widget.receiverId,
                          isTextMessage: true,
                          messageText: messageTextController.text,
                        ));
                        setState(() {
                          messageTextController.clear();
                          _suffixIcon = micButton;
                        });
                      },
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  });
                } else {
                  setState(() {
                    _suffixIcon = micButton;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CommonMessageSendData {
  late int receiverId;
  late bool isCustom;
  late bool isReply;
  late bool isTextMessage;
  late bool isImageMessage;
  late bool isVoiceMessage;
  late String? customType;
  late String? minimumSupportVersion;
  late String? textOnError;
  late String? customMessageContent;
  late int? messageReplied;
  late String? messageText;
  late List<XFile>? messageImage;
  late XFile? messageVoice;

  CommonMessageSendData({
    required this.receiverId,
    this.isCustom = false,
    this.isReply = false,
    this.isTextMessage = false,
    this.isImageMessage = false,
    this.isVoiceMessage = false,
    this.customType,
    this.minimumSupportVersion,
    this.textOnError,
    this.customMessageContent,
    this.messageReplied,
    this.messageText,
    this.messageImage,
    this.messageVoice,
  });
}

import 'package:flutter/scheduler.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/mini_apps/chat_room/home_page/chat_room/message_input_field/message_input_field/message_input_field.dart';
import 'package:meta_uni_app/mini_apps/chat_room/home_page/chat_room/models/message.dart';
import 'package:meta_uni_app/mini_apps/chat_room/home_page/chat_room/models/message_input_data.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';
import 'package:web_socket_channel/io.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../mini_app_manager.dart';
import 'bubble/bubble.dart';
import 'bubble/bubble_helper.dart';

class ChatRoomMessagePage extends StatefulWidget {
  final String chatRoomDisplayName;
  final String chatRoomName;
  final String nickname;
  final String avatar;

  const ChatRoomMessagePage({super.key, required this.chatRoomDisplayName, required this.chatRoomName, required this.nickname, required this.avatar});

  @override
  State<ChatRoomMessagePage> createState() => _ChatRoomMessagePageState();
}

class _ChatRoomMessagePageState extends State<ChatRoomMessagePage> with TickerProviderStateMixin {
  EditableTextState? editableTextState;
  late MessageBubbleHelper bubbleHelper = MessageBubbleHelper(setEditableTextState, removeContextMenu);

  late Future<dynamic> init;

  late Dio dio;
  late int uuid;
  late String jwt;

  late IOWebSocketChannel _channel;
  late bool isOnline = false;
  late int charRoomOnlineNumber = 0;

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

  _init() async {
    await _initDio();
    final prefs = await SharedPreferences.getInstance();
    jwt = prefs.getString('jwt')!;
    uuid = prefs.getInt('uuid')!;

    //连接WebSocket，设置isOnline的值
    await _initChannel();
  }

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  _initChannel() async {
    String baseUrl = (await MiniAppManager().getCurrentMiniAppUrl())!;
    String wsUrl = "${baseUrl.replaceFirst("http", "ws")}/chatRoom/ws/${widget.chatRoomName}/${widget.nickname}";
    _channel = IOWebSocketChannel.connect(
      Uri.parse(wsUrl),
      headers: {'UUID': uuid, 'JWT': jwt},
    );
    setState(() {
      isOnline = true;
    });

    _channel.stream.listen(
      (event) async {
        Map<dynamic, dynamic> map = jsonDecode(event);
        switch (map["type"]) {
          case "CheckOnlineNumber":
            setState(() {
              charRoomOnlineNumber = map["data"];
            });
            break;
          case "NewMessage":
            Message message = Message.fromJson(map["data"]);
            setState(() {
              messages.add(message);
            });
            if (_scrollController.position.extentBefore < MediaQuery.of(context).size.height) {
              SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                _scrollController.animateTo(_scrollController.position.minScrollExtent, duration: const Duration(seconds: 1), curve: Curves.fastOutSlowIn);
              });
            } else {
              setState(() {
                numberOfUnreadMessagesInChatRoom++;
              });
            }
            if (message.isCustom && message.customType == "MembersChanged") {
              _checkOnlineNumber();
            }
            break;
          case "MessageBeRecalled":
            String messageId = map["data"];
            onRecall(messageId);
            break;
          case "BeExiled":
            Navigator.popUntil(
              context,
              ModalRoute.withName('/miniApps/chatRoom'),
            );
            break;
        }
      },
      onDone: () async {
        setState(() {
          isOnline = false;
        });
      },
    );

    _checkOnlineNumber();
  }

  _checkOnlineNumber() {
    _channel.sink.add(
      jsonEncode(
        {
          "type": "CheckOnlineNumber",
          "uuid": uuid,
          "jwt": jwt,
        },
      ),
    );
  }

  _closeChannel() {
    _channel.sink.close();
  }

  _reconnect() async {
    messages = [];
    numberOfUnreadMessagesInChatRoom = 0;
    messageRepliedBubble = null;
    messageReplied = null;

    await _initChannel();
  }

  final ScrollController _scrollController = ScrollController();

  toggleToReplyMode(bool isSentByMe, Message message) {
    messageRepliedBubble = MessageBubbleReadonly(
      isSentByMe: isSentByMe,
      message: message,
    );
    setState(() {
      messageReplied = message;
    });
    replyModeAnimationController.forward();
  }

  MessageBubbleReadonly? messageRepliedBubble;
  Message? messageReplied;
  late AnimationController replyModeAnimationController;
  late Animation<double> replyModeAnimation;

  late int numberOfUnreadMessagesInChatRoom = 0;

  late List<Message> messages = [];

  sendMessage(MessageInputData inputData) async {
    Map<String, dynamic> formDataMap = {
      'chatRoom': widget.chatRoomName,
      'sender.UUID': uuid,
      'sender.Avatar': widget.avatar,
      'sender.Nickname': widget.nickname,
      'messageText': inputData.messageText,
    };

    if (messageReplied != null) {
      final newEntries = {
        'messageReplied.MessageId': messageReplied!.messageId,
        'messageReplied.Sender.UUID': messageReplied!.sender.uuid,
        'messageReplied.Sender.Nickname': messageReplied!.sender.nickname,
        'messageReplied.Sender.Avatar': messageReplied!.sender.avatar,
        'messageReplied.CreatedTime': messageReplied!.createdTime,
        'messageReplied.IsCustom': messageReplied!.isCustom,
        'messageReplied.IsRecalled': messageReplied!.isRecalled,
        'messageReplied.IsReply': false,
        'messageReplied.IsMediaMessage': messageReplied!.isMediaMessage,
        'messageReplied.IsVoiceMessage': messageReplied!.isVoiceMessage,
        'messageReplied.CustomType': messageReplied!.customType,
        'messageReplied.MinimumSupportVersion': messageReplied!.minimumSupportVersion,
        'messageReplied.TextOnError': messageReplied!.textOnError,
        'messageReplied.CustomMessageContent': messageReplied!.customMessageContent,
        'messageReplied.MessageReplied': null,
        'messageReplied.MessageText': messageReplied!.messageText,
        'messageReplied.MessageVoice': messageReplied!.messageVoice,
      };
      formDataMap.addEntries(newEntries.entries);
      if (messageReplied!.isMediaMessage) {
        for (int i = 0; i < messageReplied!.messageMedias!.length; i++) {
          final newEntries = {
            'messageReplied.MessageMedias[$i].Type': messageReplied!.messageMedias![i].type,
            'messageReplied.MessageMedias[$i].Url': messageReplied!.messageMedias![i].url,
            'messageReplied.MessageMedias[$i].AspectRatio': messageReplied!.messageMedias![i].aspectRatio,
            'messageReplied.MessageMedias[$i].PreviewImage': messageReplied!.messageMedias![i].previewImage,
            'messageReplied.MessageMedias[$i].TimeTotal': messageReplied!.messageMedias![i].timeTotal?.inMilliseconds,
          };
          formDataMap.addEntries(newEntries.entries);
        }
      }
    }

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
      response = await dio.post(
        '/message',
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
          Message message = Message.fromJson(
            response.data['data'],
          );
          setState(() {
            messages.add(message);
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
        //Message:"发送消息失败，该聊天室不存在"
        case 3:
        //Message:"发送消息失败，文字内容与媒体文件内容不能同时为空"
        case 4:
        //Message:"发送消息失败，上传媒体文件数超过限制"
        case 5:
          //Message:"发送消息失败，禁止上传规定格式以外的文件"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        case 6:
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

  onRecall(String messageId) {
    for (var message in messages) {
      if (message.messageId == messageId) {
        message.isRecalled = true;
      }
      if (message.isReply && message.messageReplied!.messageId == messageId) {
        message.messageReplied!.isRecalled = true;
      }
      if (messageReplied != null && messageReplied!.messageId == messageId) {
        messageReplied!.isRecalled = true;
      }
    }
    setState(() {});
  }

  onDelete(String messageId) {
    for (var message in messages) {
      if (message.messageId == messageId) {
        message.isDeleted = true;
      }
      if (message.isReply && message.messageReplied!.messageId == messageId) {
        message.messageReplied!.isDeleted = true;
      }
      if (messageReplied != null && messageReplied!.messageId == messageId) {
        messageReplied!.isDeleted = true;
      }
    }
    setState(() {});
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
      if (numberOfUnreadMessagesInChatRoom > 0 && _scrollController.position.extentBefore < MediaQuery.of(context).size.height) {
        setState(() {
          numberOfUnreadMessagesInChatRoom = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _closeChannel();
    _scrollController.dispose();
    replyModeAnimationController.dispose();

    super.dispose();
  }

  Key centerKey = const Key("centerKey");

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
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
            title: Column(
              children: [
                Text(widget.chatRoomDisplayName),
                Text(
                  "$charRoomOnlineNumber人在线",
                  style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {
                  bubbleHelper.removeContextMenu();
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("小贴士："),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: [
                              Text(
                                "某人的发言令你感到不适？",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Text("\t\t\t\t\t\t\t\t点击头像，对TA使用公投吧！"),
                              const Text("\t\t\t\t\t\t\t\t被投票放逐出聊天室的家伙在一小时内都无法再进入该聊天室。"),
                              Container(
                                height: 20,
                              ),
                              Text(
                                "想要和某人私聊？",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Text("\t\t\t\t\t\t\t\t点击头像，向TA发送私聊请求吧！"),
                              const Text("\t\t\t\t\t\t\t\t对方同意后，将在主界面消息页中新建会话。（发送请求会使对方看到您的真实网名与头像）"),
                            ],
                          ),
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("我知道了"),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(
                  Icons.quiz_outlined,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: FutureBuilder(
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
                    if (!isOnline) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off_outlined,
                              size: 36,
                            ),
                            const Text("掉线啦"),
                            Container(
                              height: 5,
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _reconnect();
                              },
                              child: const Text(
                                "重新连接",
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Stack(
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
                                        if (messages[index].sender.uuid == uuid) {
                                          isSentByMe = true;
                                        } else {
                                          isSentByMe = false;
                                        }
                                        return MessageBubble(
                                          isSentByMe: isSentByMe,
                                          chatRoomName: widget.chatRoomName,
                                          bubbleHelper: bubbleHelper,
                                          message: messages[index],
                                          onReply: toggleToReplyMode,
                                          onRecall: onRecall,
                                          onDelete: onDelete,
                                        );
                                      },
                                      childCount: messages.length,
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: EdgeInsets.zero,
                                    key: centerKey,
                                  ),
                                ],
                              ),
                              numberOfUnreadMessagesInChatRoom == 0
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
                                            numberOfUnreadMessagesInChatRoom > 99 ? "99+" : numberOfUnreadMessagesInChatRoom.toString(),
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
                          ),
                        ),
                        MessageInputField(
                          removeContextMenu: bubbleHelper.removeContextMenu,
                          sendMessage: sendMessage,
                        ),
                      ],
                    );
                  default:
                    return const Center(
                      child: CupertinoActivityIndicator(),
                    );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta_uni_app/mini_apps/chat_room/home_page/chat_room/bubble/bubble_helper.dart';
import 'package:meta_uni_app/reusable_components/check_version/check_version.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../../../../reusable_components/formatter/date_time_formatter/date_time_formatter.dart';
import '../../../../../reusable_components/logout/logout.dart';
import '../../../../../reusable_components/media/models/view_media_metadata.dart';
import '../../../../../reusable_components/media/video/video_preview.dart';
import '../../../../../reusable_components/media/view_media_page.dart';
import '../../../../../reusable_components/rich_text_with_sticker/rich_text_with_sticker.dart';
import '../../../../../reusable_components/route_animation/route_animation.dart';
import '../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../mini_app_manager.dart';
import '../models/message.dart';
import 'custom/referendum/referendum_card.dart';
import 'custom/referendum_result/referendum_result_card.dart';

class MessageBubble extends StatefulWidget {
  final bool isSentByMe;
  final String chatRoomName;
  final MessageBubbleHelper bubbleHelper;
  final Message message;
  final Function(bool isSentByMe, Message message) onReply;
  final Function(String messageId) onRecall;
  final Function(String messageId) onDelete;

  const MessageBubble({
    super.key,
    required this.isSentByMe,
    required this.chatRoomName,
    required this.bubbleHelper,
    required this.message,
    required this.onReply,
    required this.onRecall,
    required this.onDelete,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with TickerProviderStateMixin {
  late AnimationController slideOutAnimationController;
  late Animation<Offset> slideOutAnimation;

  late AnimationController disappearAnimationController;
  late Animation<double> disappearAnimation;

  late AnimationController appearAnimationController;
  late Animation<double> appearAnimation;

  late bool shouldPlayRecallAnimation = false;

  late double longPadding = MediaQuery.of(context).size.width * 0.15;
  late EdgeInsetsGeometry bubblePadding = widget.isSentByMe ? EdgeInsets.fromLTRB(longPadding, 5, 10, 5) : EdgeInsets.fromLTRB(10, 5, longPadding, 5);
  late EdgeInsetsGeometry containerPadding = widget.isSentByMe ? const EdgeInsets.fromLTRB(10, 10, 15, 15) : const EdgeInsets.fromLTRB(15, 10, 10, 15);

  onDelete() async {
    await slideOutAnimationController.forward();
    await disappearAnimationController.forward();
    setState(() {
      widget.message.isDeleted = true;
    });
    widget.onDelete(widget.message.messageId);
  }

  onRecall() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt')!;
    final uuid = prefs.getInt('uuid')!;

    try {
      Response response;
      response = await dio.put(
        '/message/recall/${widget.chatRoomName}/${widget.message.messageId}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          await slideOutAnimationController.forward();
          await disappearAnimationController.forward();
          setState(() {
            shouldPlayRecallAnimation = true;
            widget.message.isRecalled = true;
            appearAnimationController.forward();
          });
          widget.onRecall(widget.message.messageId);
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
          //Message:"撤回消息失败，该聊天室不存在"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
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

  onHoldReferendum(int targetUUID, String avatar, String nickname, String reason) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt')!;
    final uuid = prefs.getInt('uuid')!;

    try {
      Response response;
      response = await dio.post(
        '/chatRoom/referendum/${widget.chatRoomName}',
        data: {
          'targetUser': {
            'uuid': targetUUID,
            'avatar': avatar,
            'nickname': nickname,
          },
          'reason': reason,
        },
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
        //Message:"发动公投失败，该聊天室不存在"
        case 3:
        //Message:"发动公投失败，目标用户已离开该聊天室"
        case 4:
          //Message:"同一用户在五分钟内无法受到来自同一间聊天室的多次放逐公投"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
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

  onSendChatRequest(int targetUUID, String greetText) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt')!;
    final uuid = prefs.getInt('uuid')!;

    try {
      Response response;
      response = await dio.post(
        '/chatRoom/chatRequest',
        data: {
          'targetUser': targetUUID,
          'greetText': greetText,
        },
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
        //Message:"发送私聊请求失败，您向该用户发送私聊请求的操作太过频繁"
        case 3:
          //Message:"根据后端RPC调用结果可能返回不同的Message"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
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

  late ContextMenuButtonItem quoteButton = ContextMenuButtonItem(
    label: '回复',
    onPressed: () {
      widget.bubbleHelper.removeContextMenu();
      widget.onReply(widget.isSentByMe, widget.message);
    },
  );
  late ContextMenuButtonItem recallButton = ContextMenuButtonItem(
    label: '撤回',
    onPressed: () {
      ContextMenuController.removeAny();
      onRecall();
    },
  );
  late ContextMenuButtonItem deleteButton = ContextMenuButtonItem(
    label: '删除',
    onPressed: () {
      ContextMenuController.removeAny();
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('确定要删除吗？'),
            content: const SingleChildScrollView(
              child: ListBody(
                children: [
                  Text('删除后该消息将不会再显示在您的消息列表中，但聊天室内的其他人依旧可以看到该消息。'),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('取消'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FilledButton(
                child: const Text('确定删除'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  onDelete();
                },
              ),
            ],
          );
        },
      );
    },
  );

  late Widget Function(BuildContext, EditableTextState) selectableTextContextMenuBuilder = widget.isSentByMe
      ? (BuildContext context, EditableTextState editableTextState) {
          final List<ContextMenuButtonItem> buttonItems = editableTextState.contextMenuButtonItems;
          buttonItems.add(quoteButton);
          buttonItems.add(recallButton);
          buttonItems.add(deleteButton);
          widget.bubbleHelper.setEditableTextState(editableTextState);
          return ContextMenu(
            anchor: editableTextState.contextMenuAnchors.primaryAnchor,
            children: buttonItems,
          );
        }
      : (BuildContext context, EditableTextState editableTextState) {
          final List<ContextMenuButtonItem> buttonItems = editableTextState.contextMenuButtonItems;
          buttonItems.add(quoteButton);
          buttonItems.add(deleteButton);
          widget.bubbleHelper.setEditableTextState(editableTextState);
          return ContextMenu(anchor: editableTextState.contextMenuAnchors.primaryAnchor, children: buttonItems);
        };

  late Color bubbleColor = widget.isSentByMe ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.surfaceVariant;
  late TextStyle bubbleTextStyle = widget.isSentByMe ? TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer) : TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
  late Offset contextMenuAnchor;
  final ContextMenuController contextMenuController = ContextMenuController();

  List<Widget> getMessageContent() {
    List<Widget> messageContent = [];

    if (widget.message.isReply) {
      messageContent.add(
        RepliedMessageContent(
          message: widget.message.messageReplied!,
        ),
      );
    }

    if (widget.message.messageText != null && widget.message.messageText!.isNotEmpty) {
      messageContent.add(
        RichTextWithSticker(
          text: widget.message.messageText!,
          textStyle: bubbleTextStyle,
          isSelectable: true,
          contextMenuBuilder: selectableTextContextMenuBuilder,
        ),
      );
    }

    if (widget.message.isMediaMessage) {
      List<ViewMediaMetadata> viewMediaMetadataList = [];
      int currentIndex = 0;

      for (var media in widget.message.messageMedias!) {
        String heroTag = DateTime.now().microsecondsSinceEpoch.toString();

        if (media.type == "image") {
          viewMediaMetadataList.add(
            ViewMediaMetadata(
              type: "image",
              heroTag: heroTag,
              imageURL: media.url,
            ),
          );
          int index = currentIndex;
          messageContent.add(
            Container(
              margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      routeFadeIn(
                        page: ViewMediaPage(
                          dataList: viewMediaMetadataList,
                          initialPage: index,
                          canShare: true,
                        ),
                        opaque: false,
                      ),
                    );
                  },
                  child: Hero(
                    tag: heroTag,
                    child: AspectRatio(
                      aspectRatio: media.aspectRatio,
                      child: CachedNetworkImage(
                        fadeInDuration: const Duration(milliseconds: 800),
                        fadeOutDuration: const Duration(milliseconds: 200),
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                        imageUrl: media.url,
                        imageBuilder: (context, imageProvider) => Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.error_outline),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          currentIndex++;
        } else if (media.type == "video") {
          VideoPlayerController controller = VideoPlayerController.networkUrl(
            Uri.parse(media.url),
          );
          viewMediaMetadataList.add(
            ViewMediaMetadata(type: "video", heroTag: heroTag, videoPlayerController: controller),
          );
          int index = currentIndex;
          messageContent.add(
            Container(
              margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VideoPreview(
                  previewImage: media.previewImage!,
                  aspectRatio: media.aspectRatio,
                  timeTotal: media.timeTotal!,
                  controller: controller,
                  heroTag: heroTag,
                  jumpFunction: () {
                    Navigator.push(
                      context,
                      routeFadeIn(
                        page: ViewMediaPage(
                          dataList: viewMediaMetadataList,
                          initialPage: index,
                          canShare: true,
                        ),
                        opaque: false,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
          currentIndex++;
        }
      }
    }

    return messageContent;
  }

  Widget getBubbleContent() {
    return Flexible(
      child: Column(
        crossAxisAlignment: widget.isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          InkWell(
            onTapDown: (details) {
              contextMenuAnchor = details.globalPosition;
              widget.bubbleHelper.removeContextMenu();
            },
            onLongPress: () {
              widget.bubbleHelper.setEditableTextState(null);
              contextMenuController.show(
                context: context,
                contextMenuBuilder: (context) {
                  final List<ContextMenuButtonItem> buttonItems = [];
                  buttonItems.add(quoteButton);
                  if (widget.isSentByMe) {
                    buttonItems.add(recallButton);
                  }
                  buttonItems.add(deleteButton);
                  return ContextMenu(anchor: contextMenuAnchor, children: buttonItems);
                },
              );
            },
            customBorder: BubbleInkWellBorder(widget.isSentByMe),
            child: ClipPath(
              clipper: BubbleClipper(widget.isSentByMe),
              child: Container(
                color: bubbleColor,
                padding: containerPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: getMessageContent(),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 15,
            child: Text(
              widget.isSentByMe
                  ? "${getFormattedDateTime(dateTime: widget.message.createdTime, shouldShowTime: true)}  ${widget.message.sender.nickname}"
                  : "${widget.message.sender.nickname}  ${getFormattedDateTime(dateTime: widget.message.createdTime, shouldShowTime: true)}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall!.apply(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> getWidgets() {
    List<Widget> widgets = [];
    final bubbleContent = getBubbleContent();

    if (widget.isSentByMe) {
      widgets.add(bubbleContent);
      widgets.add(
        Container(
          width: 10,
        ),
      );
      widgets.add(
        AvatarReadonly(
          widget.message.sender.uuid,
          widget.message.sender.avatar,
        ),
      );
    } else {
      // uuid == 0,表明是聊天室系统消息
      if (widget.message.sender.uuid == 0) {
        widgets.add(
          AvatarReadonly(
            widget.message.sender.uuid,
            widget.message.sender.avatar,
          ),
        );
      } else {
        widgets.add(
          Avatar(
            widget.message.sender.uuid,
            widget.message.sender.nickname,
            widget.message.sender.avatar,
            onHoldReferendum,
            onSendChatRequest,
          ),
        );
      }
      widgets.add(
        Container(
          width: 10,
        ),
      );
      widgets.add(bubbleContent);
    }
    return widgets;
  }

  late Widget customMessage;

  @override
  void initState() {
    super.initState();

    slideOutAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(
      CurvedAnimation(parent: slideOutAnimationController, curve: Curves.easeOut),
    );

    disappearAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    disappearAnimation = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: disappearAnimationController, curve: Curves.easeOut),
    );

    appearAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    appearAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: appearAnimationController, curve: Curves.fastOutSlowIn),
    );
  }

  @override
  void dispose() {
    slideOutAnimationController.dispose();
    disappearAnimationController.dispose();
    appearAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isDeleted) {
      return const DeletedMessage();
    }
    if (widget.message.isRecalled) {
      return shouldPlayRecallAnimation
          ? SizeTransition(
              axis: Axis.vertical,
              sizeFactor: appearAnimation,
              child: ScaleTransition(
                scale: appearAnimation,
                child: RecalledMessage(widget.isSentByMe, widget.message.sender.nickname),
              ),
            )
          : RecalledMessage(widget.isSentByMe, widget.message.sender.nickname);
    }
    if (widget.message.isCustom) {
      String customType = widget.message.customType!;
      String minimumSupportVersion = widget.message.minimumSupportVersion!;
      String textOnError = widget.message.textOnError!;
      String customMessageContent = widget.message.customMessageContent!;

      if (checkVersion(minimumSupportVersion)) {
        switch (customType) {
          case "MembersChanged":
            if (mounted) {
              customMessage = CommonWrapper(
                child: Text(
                  customMessageContent,
                  style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              );
            }
            break;
          case "Referendum":
            if (mounted) {
              onVote() {
                Map<dynamic, dynamic> map = jsonDecode(customMessageContent);
                map['hasVoted'] = true;
                setState(() {
                  widget.message.customMessageContent = jsonEncode(map);
                });
              }

              customMessage = Center(
                child: Column(
                  children: [
                    Text(
                      getFormattedDateTime(
                        dateTime: widget.message.createdTime,
                        shouldShowTime: true,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.apply(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    ReferendumCard(
                      referendumCardData: ReferendumCardData.fromJson(
                        jsonDecode(customMessageContent),
                      ),
                      onVote: onVote,
                    ),
                  ],
                ),
              );
            }
            break;
          case "ReferendumResult":
            if (mounted) {
              customMessage = Center(
                child: Column(
                  children: [
                    Text(
                      getFormattedDateTime(
                        dateTime: widget.message.createdTime,
                        shouldShowTime: true,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.apply(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    ReferendumResultCard(
                      referendumResultCardData: ReferendumResultCardData.fromJson(
                        jsonDecode(customMessageContent),
                      ),
                    ),
                  ],
                ),
              );
            }
            break;
          default:
            if (mounted) {
              customMessage = Column(
                children: [
                  Text(
                    getFormattedDateTime(
                      dateTime: widget.message.createdTime,
                      shouldShowTime: true,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.apply(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  CommonWrapper(
                    child: Text(
                      textOnError,
                      style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              );
            }
            break;
        }
      } else {
        if (mounted) {
          customMessage = Column(
            children: [
              Text(
                getFormattedDateTime(
                  dateTime: widget.message.createdTime,
                  shouldShowTime: true,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.apply(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              CommonWrapper(
                child: Text(
                  textOnError,
                  style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          );
        }
      }
      return customMessage;
    }
    return SizeTransition(
      axis: Axis.vertical,
      sizeFactor: disappearAnimation,
      child: SlideTransition(
        position: slideOutAnimation,
        transformHitTests: false,
        textDirection: widget.isSentByMe ? TextDirection.ltr : TextDirection.rtl,
        child: Padding(
          padding: bubblePadding,
          child: Row(
            mainAxisAlignment: widget.isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: getWidgets(),
          ),
        ),
      ),
    );
  }
}

class MessageBubbleReadonly extends StatefulWidget {
  final bool isSentByMe;
  final Message message;

  const MessageBubbleReadonly({
    super.key,
    required this.isSentByMe,
    required this.message,
  });

  @override
  State<MessageBubbleReadonly> createState() => _MessageBubbleReadonlyState();
}

class _MessageBubbleReadonlyState extends State<MessageBubbleReadonly> {
  late double longPadding = MediaQuery.of(context).size.width * 0.15;
  late EdgeInsetsGeometry bubblePadding = widget.isSentByMe ? EdgeInsets.fromLTRB(longPadding, 5, 10, 5) : EdgeInsets.fromLTRB(10, 5, longPadding, 5);
  late EdgeInsetsGeometry containerPadding = widget.isSentByMe ? const EdgeInsets.fromLTRB(10, 10, 15, 15) : const EdgeInsets.fromLTRB(15, 10, 10, 15);

  late Color bubbleColor = widget.isSentByMe ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.surfaceVariant;
  late TextStyle bubbleTextStyle = widget.isSentByMe ? TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer) : TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);

  List<Widget> getMessageContent() {
    List<Widget> messageContent = [];

    if (widget.message.isReply) {
      messageContent.add(
        RepliedMessageContent(
          message: widget.message.messageReplied!,
        ),
      );
    }
    if (widget.message.messageText != null && widget.message.messageText!.isNotEmpty) {
      messageContent.add(
        RichTextWithSticker(
          text: widget.message.messageText!,
          textStyle: bubbleTextStyle,
        ),
      );
    }

    if (widget.message.isMediaMessage) {
      List<ViewMediaMetadata> viewMediaMetadataList = [];
      int currentIndex = 0;

      for (var media in widget.message.messageMedias!) {
        String heroTag = DateTime.now().microsecondsSinceEpoch.toString();

        if (media.type == "image") {
          viewMediaMetadataList.add(
            ViewMediaMetadata(
              type: "image",
              heroTag: heroTag,
              imageURL: media.url,
            ),
          );
          int index = currentIndex;
          messageContent.add(
            Container(
              margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      routeFadeIn(
                        page: ViewMediaPage(
                          dataList: viewMediaMetadataList,
                          initialPage: index,
                          canShare: true,
                        ),
                        opaque: false,
                      ),
                    );
                  },
                  child: Hero(
                    tag: heroTag,
                    child: AspectRatio(
                      aspectRatio: media.aspectRatio,
                      child: CachedNetworkImage(
                        fadeInDuration: const Duration(milliseconds: 800),
                        fadeOutDuration: const Duration(milliseconds: 200),
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                        imageUrl: media.url,
                        imageBuilder: (context, imageProvider) => Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.error_outline),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          currentIndex++;
        } else if (media.type == "video") {
          VideoPlayerController controller = VideoPlayerController.networkUrl(
            Uri.parse(media.url),
          );
          viewMediaMetadataList.add(
            ViewMediaMetadata(type: "video", heroTag: heroTag, videoPlayerController: controller),
          );
          int index = currentIndex;
          messageContent.add(
            Container(
              margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VideoPreview(
                  previewImage: media.previewImage!,
                  aspectRatio: media.aspectRatio,
                  timeTotal: media.timeTotal!,
                  controller: controller,
                  heroTag: heroTag,
                  jumpFunction: () {
                    Navigator.push(
                      context,
                      routeFadeIn(
                        page: ViewMediaPage(
                          dataList: viewMediaMetadataList,
                          initialPage: index,
                          canShare: true,
                        ),
                        opaque: false,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
          currentIndex++;
        }
      }
    }

    return messageContent;
  }

  Widget getBubbleContent() {
    return Flexible(
      child: Column(
        crossAxisAlignment: widget.isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ClipPath(
            clipper: BubbleClipper(widget.isSentByMe),
            child: Container(
              color: bubbleColor,
              padding: containerPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: getMessageContent(),
              ),
            ),
          ),
          SizedBox(
            height: 15,
            child: Text(
              widget.isSentByMe
                  ? "${getFormattedDateTime(dateTime: widget.message.createdTime, shouldShowTime: true)}  ${widget.message.sender.nickname}"
                  : "${widget.message.sender.nickname}  ${getFormattedDateTime(dateTime: widget.message.createdTime, shouldShowTime: true)}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall!.apply(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> getWidgets() {
    List<Widget> widgets = [];
    final bubbleContent = getBubbleContent();

    if (widget.isSentByMe) {
      widgets.add(bubbleContent);
      widgets.add(Container(
        width: 10,
      ));
      widgets.add(
        AvatarReadonly(widget.message.sender.uuid, widget.message.sender.avatar),
      );
    } else {
      widgets.add(
        AvatarReadonly(widget.message.sender.uuid, widget.message.sender.avatar),
      );
      widgets.add(Container(
        width: 10,
      ));
      widgets.add(bubbleContent);
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isDeleted) {
      return const DeletedMessage();
    }
    if (widget.message.isRecalled) {
      return RecalledMessage(widget.isSentByMe, widget.message.sender.nickname);
    }
    return Padding(
      padding: bubblePadding,
      child: Row(
        mainAxisAlignment: widget.isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: getWidgets(),
      ),
    );
  }
}

class RepliedMessageContent extends StatefulWidget {
  final Message message;

  const RepliedMessageContent({super.key, required this.message});

  @override
  State<RepliedMessageContent> createState() => _RepliedMessageContentState();
}

class _RepliedMessageContentState extends State<RepliedMessageContent> {
  List<Widget> getContent() {
    List<Widget> content = [];
    content.add(
      Text(
        "${widget.message.sender.nickname}  ${getFormattedDateTime(dateTime: widget.message.createdTime, shouldShowTime: true)}",
        style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurface),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    content.add(
      Container(
        height: 5,
      ),
    );

    if (widget.message.isDeleted) {
      content.add(
        SelectableText(
          '该消息已被删除',
          style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurface),
        ),
      );
      return content;
    }

    if (widget.message.isRecalled) {
      content.add(
        SelectableText(
          '该消息已被撤回',
          style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurface),
        ),
      );
      return content;
    }

    if (widget.message.isCustom) {
      //处理特殊消息
    } else {
      if (widget.message.messageText != null && widget.message.messageText!.isNotEmpty) {
        content.add(
          RichTextWithSticker(
            text: widget.message.messageText!,
            maxLines: null,
            textStyle: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurface),
            isSelectable: true,
          ),
        );
      }
    }

    if (widget.message.isMediaMessage) {
      List<ViewMediaMetadata> viewMediaMetadataList = [];
      int currentIndex = 0;

      for (var media in widget.message.messageMedias!) {
        String heroTag = DateTime.now().microsecondsSinceEpoch.toString();

        if (media.type == "image") {
          viewMediaMetadataList.add(
            ViewMediaMetadata(
              type: "image",
              heroTag: heroTag,
              imageURL: media.url,
            ),
          );
          int index = currentIndex;
          content.add(
            Container(
              margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      routeFadeIn(
                        page: ViewMediaPage(
                          dataList: viewMediaMetadataList,
                          initialPage: index,
                          canShare: true,
                        ),
                        opaque: false,
                      ),
                    );
                  },
                  child: Hero(
                    tag: heroTag,
                    child: AspectRatio(
                      aspectRatio: media.aspectRatio,
                      child: CachedNetworkImage(
                        fadeInDuration: const Duration(milliseconds: 800),
                        fadeOutDuration: const Duration(milliseconds: 200),
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                        imageUrl: media.url,
                        imageBuilder: (context, imageProvider) => Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.error_outline),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          currentIndex++;
        } else if (media.type == "video") {
          VideoPlayerController controller = VideoPlayerController.networkUrl(
            Uri.parse(media.url),
          );
          viewMediaMetadataList.add(
            ViewMediaMetadata(type: "video", heroTag: heroTag, videoPlayerController: controller),
          );
          int index = currentIndex;
          content.add(
            Container(
              margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VideoPreview(
                  previewImage: media.previewImage!,
                  aspectRatio: media.aspectRatio,
                  timeTotal: media.timeTotal!,
                  controller: controller,
                  heroTag: heroTag,
                  jumpFunction: () {
                    Navigator.push(
                      context,
                      routeFadeIn(
                        page: ViewMediaPage(
                          dataList: viewMediaMetadataList,
                          initialPage: index,
                          canShare: true,
                        ),
                        opaque: false,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
          currentIndex++;
        }
      }
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 5),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
        borderRadius: const BorderRadius.all(
          Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: getContent(),
      ),
    );
  }
}

class CommonWrapper extends StatelessWidget {
  final Widget child;

  const CommonWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: const BorderRadius.all(
            Radius.circular(4.0),
          ),
        ),
        child: child,
      ),
    );
  }
}

class DeletedMessage extends StatelessWidget {
  const DeletedMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class RecalledMessage extends StatelessWidget {
  final bool isSentByMe;
  final String userName;

  const RecalledMessage(this.isSentByMe, this.userName, {super.key});

  @override
  Widget build(BuildContext context) {
    return CommonWrapper(
      child: Text(
        isSentByMe ? "你 撤回了一条消息" : "$userName 撤回了一条消息",
        style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final int uuid;
  final String nickname;
  final String avatar;
  final Function(int uuid, String avatar, String nickname, String reason) onHoldReferendum;
  final Function(int uuid, String greetText) onSendChatRequest;

  const Avatar(this.uuid, this.nickname, this.avatar, this.onHoldReferendum, this.onSendChatRequest, {super.key});

  showActionBottomSheet(String action, context) {
    String text1 = "";
    String text2 = "";
    String text3 = "";
    switch (action) {
      case "HoldReferendum":
        text1 = "对 ";
        text2 = " $nickname 发动公投";
        text3 = "放逐理由：";
        break;
      case "SendChatRequest":
        text1 = "向 ";
        text2 = " $nickname 发送私聊请求";
        text3 = "打个招呼：";
        break;
      default:
        return;
    }

    final TextEditingController textController = TextEditingController();
    final FocusNode textFocusNode = FocusNode();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                  child: Row(
                    children: [
                      Text(
                        text1,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                        child: CachedNetworkImage(
                          fadeInDuration: const Duration(milliseconds: 800),
                          fadeOutDuration: const Duration(milliseconds: 200),
                          placeholder: (context, url) => CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            child: const CupertinoActivityIndicator(),
                          ),
                          imageUrl: avatar,
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            radius: 20,
                            backgroundImage: imageProvider,
                          ),
                          errorWidget: (context, url, error) => CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            child: const Icon(Icons.error_outline),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          text2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: textController,
                        focusNode: textFocusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                          prefixIcon: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                                child: Text(
                                  text3,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                        inputFormatters: [
                          //只允许输入最多50个字符
                          LengthLimitingTextInputFormatter(50),
                        ],
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.done,
                        onTapOutside: (details) {
                          textFocusNode.unfocus();
                        },
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
                              switch (action) {
                                case "HoldReferendum":
                                  onHoldReferendum(uuid, avatar, nickname, textController.text);
                                  break;
                                case "SendChatRequest":
                                  onSendChatRequest(uuid, textController.text);
                                  break;
                              }
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
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(2),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              iconPadding: const EdgeInsets.all(0),
              icon: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.close_outlined,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: nickname,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextSpan(
                            text: " 太可恶了？",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const Text("\t\t\t\t\t\t\t\t对TA使用公投吧！"),
                    const Text("\t\t\t\t\t\t\t\t被投票放逐出聊天室的家伙在一小时内都无法再进入该聊天室。"),
                    Container(
                      height: 20,
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "想和 ",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextSpan(
                            text: nickname,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextSpan(
                            text: " 私聊？",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const Text("\t\t\t\t\t\t\t\t向TA发送私聊请求吧！"),
                    const Text("\t\t\t\t\t\t\t\t对方同意后，将在主界面消息页中新建会话。（发送请求会使对方看到您的真实网名与头像）"),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showActionBottomSheet("HoldReferendum", context);
                  },
                  child: const Text("发动公投"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showActionBottomSheet("SendChatRequest", context);
                  },
                  child: const Text("发起私聊"),
                ),
              ],
            );
          },
        );
      },
      child: CachedNetworkImage(
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
      ),
    );
  }
}

class AvatarReadonly extends StatelessWidget {
  final int uuid;
  final String avatar;

  const AvatarReadonly(this.uuid, this.avatar, {super.key});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
        fadeInDuration: const Duration(milliseconds: 800),
        fadeOutDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => SizedBox(
          width: 45,
          height: 45,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: const Center(
              child: CupertinoActivityIndicator(),
            ),
          ),
        ),
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
        errorWidget: (context, url, error) => SizedBox(
          width: 45,
          height: 45,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: const Center(
              child: Icon(Icons.error_outline),
            ),
          ),
        )
    );
  }
}

class BubbleClipper extends CustomClipper<Path> {
  final bool isSentByMe;
  final double arrowSize = 5;
  final Radius radius = const Radius.circular(12);

  const BubbleClipper(this.isSentByMe);

  @override
  Path getClip(Size size) {
    Path path = Path();
    if (isSentByMe) {
      path.moveTo(size.width, size.height);
      path.lineTo(size.width - (arrowSize * 2), size.height - arrowSize);
      path.lineTo(size.width - arrowSize, size.height - (arrowSize * 2));

      path.addRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(0, 0, size.width - arrowSize, size.height - arrowSize), topLeft: radius, topRight: radius, bottomLeft: radius),
      );
    } else {
      path.moveTo(0, size.height);
      path.lineTo(0 + arrowSize, size.height - (arrowSize * 2));
      path.lineTo(0 + (arrowSize * 2), size.height - arrowSize);

      path.addRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(arrowSize, 0, size.width - arrowSize, size.height - arrowSize), topLeft: radius, topRight: radius, bottomRight: radius),
      );
    }

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class BubbleInkWellBorder extends ShapeBorder {
  final bool isSentByMe;

  const BubbleInkWellBorder(this.isSentByMe);

  @override
  // TODO: implement dimensions
  EdgeInsetsGeometry get dimensions => throw UnimplementedError();

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    // TODO: implement getInnerPath
    throw UnimplementedError();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path();
    const double arrowSize = 5;
    const Radius radius = Radius.circular(12);

    if (isSentByMe) {
      path.addRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(-arrowSize, -arrowSize, rect.width + arrowSize, rect.height + arrowSize), topLeft: radius, topRight: radius, bottomLeft: radius),
      );
    } else {
      path.addRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(0, -arrowSize, rect.width + arrowSize, rect.height + arrowSize), topLeft: radius, topRight: radius, bottomRight: radius),
      );
    }

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // TODO: implement paint
  }

  @override
  ShapeBorder scale(double t) {
    // TODO: implement scale
    throw UnimplementedError();
  }
}

class ContextMenu extends StatelessWidget {
  final Offset anchor;
  final List<ContextMenuButtonItem> children;

  const ContextMenu({
    super.key,
    required this.anchor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: TextSelectionToolbarAnchors(primaryAnchor: anchor),
      buttonItems: children,
    );
  }
}

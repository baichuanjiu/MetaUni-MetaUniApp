import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/database/models/friend/friendship.dart';
import 'package:meta_uni_app/models/dio_model.dart';
import 'package:meta_uni_app/reusable_components/formatter/date_time_formatter/date_time_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:video_player/video_player.dart';
import '../../../../../bloc/bloc_manager.dart';
import '../../../../../bloc/chat_list_tile/models/chat_list_tile_update_data.dart';
import '../../../../../database/database_manager.dart';
import '../../../../../database/models/message/common_message.dart';
import '../../../../../database/models/user/brief_user_information.dart';
import '../../../../../database/models/user/user_sync_table.dart';
import '../../../../../reusable_components/logout/logout.dart';
import '../../../../../reusable_components/media/models/view_media_metadata.dart';
import '../../../../../reusable_components/media/video/video_preview.dart';
import '../../../../../reusable_components/media/view_media_page.dart';
import '../../../../../reusable_components/rich_text_with_sticker/rich_text_with_sticker.dart';
import '../../../../../reusable_components/route_animation/route_animation.dart';
import '../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import 'bubble_helper.dart';

class CommonMessageBubble extends StatefulWidget {
  final bool isSentByMe;
  final CommonMessageBubbleHelper bubbleHelper;
  final BriefUserInformation sender;
  final CommonMessage message;
  final bool isRead;
  final DateTime? readTime;
  final Function(bool isSentByMe, BriefUserInformation sender, CommonMessage message, bool isRead, DateTime? readTime) onReply;

  const CommonMessageBubble({
    super.key,
    required this.isSentByMe,
    required this.bubbleHelper,
    required this.sender,
    required this.message,
    this.isRead = false,
    this.readTime,
    required this.onReply,
  });

  @override
  State<CommonMessageBubble> createState() => _CommonMessageBubbleState();
}

class _CommonMessageBubbleState extends State<CommonMessageBubble> with TickerProviderStateMixin {
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

  deleteCommonMessage(CommonMessage message, int uuid) async {
    Database database = await DatabaseManager().getDatabase;

    await database.transaction(
      (transaction) async {
        CommonMessageProviderWithTransaction commonMessageProviderWithTransaction = CommonMessageProviderWithTransaction(transaction);

        commonMessageProviderWithTransaction.update(message.toSql(), message.id);

        UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
        userSyncTableProviderWithTransaction.updateSequenceForCommonMessages(uuid, message.sequence);
      },
    );
  }

  void onDelete() async {
    DioModel dioModel = DioModel();

    final prefs = await SharedPreferences.getInstance();
    int uuid = prefs.getInt('uuid')!;
    String jwt = prefs.getString('jwt')!;

    try {
      Response response;
      response = await dioModel.dio.delete(
        '/metaUni/messageAPI/commonMessage/${widget.message.id}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          CommonMessage message = CommonMessage.fromJson(response.data['data']);
          await deleteCommonMessage(message, uuid);
          BlocManager().chatListTileDataCubit.shouldUpdate(
                ChatListTileUpdateData(chatId: message.chatId, messageBeDeleted: true, messageBeDeletedId: message.id),
              );
          await slideOutAnimationController.forward();
          await disappearAnimationController.forward();
          setState(() {
            widget.message.isDeleted = true;
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
        //Message:"您正在尝试删除一条不存在的消息"
        case 3:
          //Message:"您无法删除一条不属于您的消息"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        case 5:
          //Message:"发生错误，消息删除失败"
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

  recallCommonMessage(CommonMessage message, int uuid) async {
    Database database = await DatabaseManager().getDatabase;

    await database.transaction(
      (transaction) async {
        CommonMessageProviderWithTransaction commonMessageProviderWithTransaction = CommonMessageProviderWithTransaction(transaction);

        commonMessageProviderWithTransaction.update(message.toSql(), message.id);

        UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
        userSyncTableProviderWithTransaction.updateSequenceForCommonMessages(uuid, message.sequence);
      },
    );
  }

  void onRecall() async {
    DioModel dioModel = DioModel();

    final prefs = await SharedPreferences.getInstance();
    int uuid = prefs.getInt('uuid')!;
    String jwt = prefs.getString('jwt')!;

    try {
      Response response;
      response = await dioModel.dio.put(
        '/metaUni/messageAPI/commonMessage/recall/${widget.message.id}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          CommonMessage message = CommonMessage.fromJson(response.data['data']);
          await recallCommonMessage(message, uuid);
          BlocManager().chatListTileDataCubit.shouldUpdate(
                ChatListTileUpdateData(
                  chatId: message.chatId,
                  messageBeRecalled: true,
                  messageBeRecalledId: message.id,
                ),
              );
          await slideOutAnimationController.forward();
          await disappearAnimationController.forward();
          setState(() {
            shouldPlayRecallAnimation = true;
            widget.message.isRecalled = true;
            appearAnimationController.forward();
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
        //Message:"您正在尝试撤回一条不存在的消息"
        case 3:
        //Message:"您无法撤回一条不是由您发送的消息"
        case 4:
          //Message:"您无法对已被撤回的消息再次撤回"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        case 5:
          //Message:"发生错误，消息撤回失败"
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

  final ContextMenuButtonItem forwardButton = ContextMenuButtonItem(
    label: '转发',
    onPressed: () {
      ContextMenuController.removeAny();
    },
  );
  late ContextMenuButtonItem quoteButton = ContextMenuButtonItem(
    label: '回复',
    onPressed: () {
      widget.bubbleHelper.removeContextMenu();
      widget.onReply(widget.isSentByMe, widget.sender, widget.message, widget.isRead, widget.readTime);
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
                  Text('删除后该消息将不会再显示在您的消息记录中，但对方或群聊内的其他人依旧可以看到该消息。'),
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
  final ContextMenuButtonItem selectButton = ContextMenuButtonItem(
    label: '多选',
    onPressed: () {
      ContextMenuController.removeAny();
    },
  );

  late Widget Function(BuildContext, EditableTextState) selectableTextContextMenuBuilder = widget.isSentByMe
      ? (BuildContext context, EditableTextState editableTextState) {
          final List<ContextMenuButtonItem> buttonItems = editableTextState.contextMenuButtonItems;
          buttonItems.add(forwardButton);
          buttonItems.add(quoteButton);
          buttonItems.add(recallButton);
          buttonItems.add(selectButton);
          buttonItems.add(deleteButton);
          widget.bubbleHelper.setEditableTextState(editableTextState);
          return ContextMenu(
            anchor: editableTextState.contextMenuAnchors.primaryAnchor,
            children: buttonItems,
          );
        }
      : (BuildContext context, EditableTextState editableTextState) {
          final List<ContextMenuButtonItem> buttonItems = editableTextState.contextMenuButtonItems;
          buttonItems.add(forwardButton);
          buttonItems.add(quoteButton);
          buttonItems.add(selectButton);
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
        RepliedMessageContent(messageId: widget.message.messageReplied!),
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
      List<dynamic> maps = jsonDecode(widget.message.messageMedias!);

      List<ViewMediaMetadata> viewMediaMetadataList = [];
      int currentIndex = 0;

      for (Map<String, dynamic> map in maps) {
        String heroTag = DateTime.now().microsecondsSinceEpoch.toString();
        if (map["type"] == "image") {
          viewMediaMetadataList.add(
            ViewMediaMetadata(
              type: "image",
              heroTag: heroTag,
              imageURL: map["url"],
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
                      aspectRatio: double.parse(
                        map["aspectRatio"].toString(),
                      ),
                      child: CachedNetworkImage(
                        fadeInDuration: const Duration(milliseconds: 800),
                        fadeOutDuration: const Duration(milliseconds: 200),
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                        imageUrl: map["url"],
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
        } else if (map["type"] == "video") {
          VideoPlayerController controller = VideoPlayerController.networkUrl(
            Uri.parse(map["url"]),
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
                  previewImage: map["previewImage"],
                  aspectRatio: double.parse(
                    map['aspectRatio'].toString(),
                  ),
                  timeTotal: Duration(milliseconds: map['timeTotal']),
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
                  buttonItems.add(forwardButton);
                  buttonItems.add(quoteButton);
                  if (widget.isSentByMe) {
                    buttonItems.add(recallButton);
                  }
                  buttonItems.add(selectButton);
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
            child: widget.isRead
                ? Text(
                    "已读  ${getFormattedDateTime(dateTime: widget.readTime!, shouldShowTime: true)}",
                    style: Theme.of(context).textTheme.labelSmall!.apply(color: Theme.of(context).colorScheme.outline),
                  )
                : Text(
                    getFormattedDateTime(dateTime: widget.message.createdTime, shouldShowTime: true),
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
      widgets.add(Avatar(widget.sender.uuid, widget.sender.avatar));
    } else {
      widgets.add(Avatar(widget.sender.uuid, widget.sender.avatar));
      widgets.add(Container(
        width: 10,
      ));
      widgets.add(bubbleContent);
    }
    return widgets;
  }

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
                child: RecalledMessage(widget.isSentByMe, widget.sender.nickname),
              ),
            )
          : RecalledMessage(widget.isSentByMe, widget.sender.nickname);
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

class CommonMessageBubbleReadonly extends StatefulWidget {
  final bool isSentByMe;
  final BriefUserInformation sender;
  final CommonMessage message;
  final bool isRead;
  final DateTime? readTime;

  const CommonMessageBubbleReadonly({
    super.key,
    required this.isSentByMe,
    required this.sender,
    required this.message,
    this.isRead = false,
    this.readTime,
  });

  @override
  State<CommonMessageBubbleReadonly> createState() => _CommonMessageBubbleReadonlyState();
}

class _CommonMessageBubbleReadonlyState extends State<CommonMessageBubbleReadonly> {
  late double longPadding = MediaQuery.of(context).size.width * 0.15;
  late EdgeInsetsGeometry bubblePadding = widget.isSentByMe ? EdgeInsets.fromLTRB(longPadding, 5, 10, 5) : EdgeInsets.fromLTRB(10, 5, longPadding, 5);
  late EdgeInsetsGeometry containerPadding = widget.isSentByMe ? const EdgeInsets.fromLTRB(10, 10, 15, 15) : const EdgeInsets.fromLTRB(15, 10, 10, 15);

  late Color bubbleColor = widget.isSentByMe ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.surfaceVariant;
  late TextStyle bubbleTextStyle = widget.isSentByMe ? TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer) : TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);

  List<Widget> getMessageContent() {
    List<Widget> messageContent = [];

    if (widget.message.isReply) {
      messageContent.add(
        RepliedMessageContent(messageId: widget.message.messageReplied!),
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
      List<dynamic> maps = jsonDecode(widget.message.messageMedias!);

      List<ViewMediaMetadata> viewMediaMetadataList = [];
      int currentIndex = 0;

      for (Map<String, dynamic> map in maps) {
        String heroTag = DateTime.now().microsecondsSinceEpoch.toString();
        if (map["type"] == "image") {
          viewMediaMetadataList.add(
            ViewMediaMetadata(type: "image", heroTag: heroTag, imageURL: map["url"]),
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
                      aspectRatio: double.parse(
                        map["aspectRatio"].toString(),
                      ),
                      child: CachedNetworkImage(
                        fadeInDuration: const Duration(milliseconds: 800),
                        fadeOutDuration: const Duration(milliseconds: 200),
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                        imageUrl: map["url"],
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
        } else if (map["type"] == "video") {
          VideoPlayerController controller = VideoPlayerController.networkUrl(
            Uri.parse(map["url"]),
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
                  previewImage: map["previewImage"],
                  aspectRatio: double.parse(
                    map['aspectRatio'].toString(),
                  ),
                  timeTotal: Duration(milliseconds: map['timeTotal']),
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
            child: widget.isRead
                ? Text(
                    "已读  ${getFormattedDateTime(dateTime: widget.readTime!, shouldShowTime: true)}",
                    style: Theme.of(context).textTheme.labelSmall!.apply(color: Theme.of(context).colorScheme.outline),
                  )
                : Text(
                    getFormattedDateTime(dateTime: widget.message.createdTime, shouldShowTime: true),
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
        AvatarReadonly(widget.sender.uuid, widget.sender.avatar),
      );
    } else {
      widgets.add(
        AvatarReadonly(widget.sender.uuid, widget.sender.avatar),
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
      return RecalledMessage(widget.isSentByMe, widget.sender.nickname);
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
  final int messageId;

  const RepliedMessageContent({super.key, required this.messageId});

  @override
  State<RepliedMessageContent> createState() => _RepliedMessageContentState();
}

class _RepliedMessageContentState extends State<RepliedMessageContent> {
  late Database database;
  late CommonMessageProvider commonMessageProvider;
  late FriendshipProvider friendshipProvider;
  late BriefUserInformationProvider briefUserInformationProvider;

  late CommonMessage? repliedMessage;
  late BriefUserInformation? sender;

  List<Widget> getContent() {
    List<Widget> content = [];
    if (repliedMessage != null) {
      content.add(
        Text(
          "${sender!.nickname}  ${getFormattedDateTime(dateTime: repliedMessage!.createdTime, shouldShowTime: true)}",
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

      if (repliedMessage!.isDeleted) {
        content.add(
          SelectableText(
            '该消息已被删除',
            style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurface),
          ),
        );
        return content;
      }

      if (repliedMessage!.isRecalled) {
        content.add(
          SelectableText(
            '该消息已被撤回',
            style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurface),
          ),
        );
        return content;
      }

      if (repliedMessage!.messageText != null && repliedMessage!.messageText!.isNotEmpty) {
        content.add(
          RichTextWithSticker(
            text: repliedMessage!.messageText!,
            maxLines: null,
            textStyle: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurface),
            isSelectable: true,
          ),
        );
      }

      if (repliedMessage!.isMediaMessage) {
        List<dynamic> maps = jsonDecode(repliedMessage!.messageMedias!);

        List<ViewMediaMetadata> viewMediaMetadataList = [];
        int currentIndex = 0;

        for (Map<String, dynamic> map in maps) {
          String heroTag = DateTime.now().microsecondsSinceEpoch.toString();
          if (map["type"] == "image") {
            viewMediaMetadataList.add(
              ViewMediaMetadata(type: "image", heroTag: heroTag, imageURL: map["url"]),
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
                        aspectRatio: double.parse(
                          map["aspectRatio"].toString(),
                        ),
                        child: CachedNetworkImage(
                          fadeInDuration: const Duration(milliseconds: 800),
                          fadeOutDuration: const Duration(milliseconds: 200),
                          placeholder: (context, url) => const Center(
                            child: CupertinoActivityIndicator(),
                          ),
                          imageUrl: map["url"],
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
          } else if (map["type"] == "video") {
            VideoPlayerController controller = VideoPlayerController.networkUrl(
              Uri.parse(map["url"]),
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
                    previewImage: map["previewImage"],
                    aspectRatio: double.parse(
                      map['aspectRatio'].toString(),
                    ),
                    timeTotal: Duration(milliseconds: map['timeTotal']),
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
    } else {
      content.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SelectableText(
              '该消息不在本地数据库中',
              style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      );
      return content;
    }
  }

  late Future<dynamic> init;

  getBriefUserInformation(int queryUUID) async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    final DioModel dioModel = DioModel();

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/userAPI/profile/brief/$queryUUID',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          Database database = await DatabaseManager().getDatabase;
          BriefUserInformationProvider briefUserInformationProvider = BriefUserInformationProvider(database);
          BriefUserInformation briefUserInformation = BriefUserInformation.fromJson(response.data['data']);
          if (await briefUserInformationProvider.get(briefUserInformation.uuid) == null) {
            briefUserInformationProvider.insert(briefUserInformation);
          } else {
            briefUserInformationProvider.update(briefUserInformation.toUpdateSql(), briefUserInformation.uuid);
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
          //Message:"没有找到目标用户的个人信息"
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

  _getData() async {
    repliedMessage = await commonMessageProvider.get(widget.messageId);
    if (repliedMessage != null) {
      String? remark = await friendshipProvider.getRemark(repliedMessage!.senderId);
      sender = await briefUserInformationProvider.get(repliedMessage!.senderId);

      if (sender == null) {
        await getBriefUserInformation(repliedMessage!.senderId);
        sender = await briefUserInformationProvider.get(repliedMessage!.senderId);
      }

      if (remark != null) {
        sender!.nickname = remark;
      }
    }
    setState(() {});
  }

  _init() async {
    database = await DatabaseManager().getDatabase;
    commonMessageProvider = CommonMessageProvider(database);
    friendshipProvider = FriendshipProvider(database);
    briefUserInformationProvider = BriefUserInformationProvider(database);

    await _getData();
  }

  @override
  void initState() {
    super.initState();

    init = _init();
  }

  @override
  void didUpdateWidget(covariant RepliedMessageContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.messageId != widget.messageId) {
      _getData();
    }
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
      child: FutureBuilder(
        future: init,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoActivityIndicator(),
                ],
              );
            case ConnectionState.active:
              return const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoActivityIndicator(),
                ],
              );
            case ConnectionState.waiting:
              return const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoActivityIndicator(),
                ],
              );
            case ConnectionState.done:
              if (snapshot.hasError) {
                return const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: getContent(),
              );
            default:
              return const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoActivityIndicator(),
                ],
              );
          }
        },
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
        child: Text(
          isSentByMe ? "你 撤回了一条消息" : "$userName 撤回了一条消息",
          style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final int uuid;
  final String avatar;

  const Avatar(this.uuid, this.avatar, {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(2),
      onTap: () {
        Navigator.pushNamed(context, '/user/profile/routeFromFriendMessagePage', arguments: uuid);
      },
      child: CachedNetworkImage(
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

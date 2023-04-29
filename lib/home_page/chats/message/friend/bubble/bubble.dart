import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../database/models/message/common_message.dart';
import '../../../../../database/models/user/brief_user_information.dart';
import 'bubble_helper.dart';


class CommonMessageBubble extends StatefulWidget {
  final bool isSentByMe;
  final CommonMessageBubbleHelper bubbleHelper;
  final BriefUserInformation sender;
  final CommonMessage message;

  const CommonMessageBubble({super.key, required this.isSentByMe, required this.bubbleHelper,required this.sender, required this.message,});

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
    late double longPadding = MediaQuery.of(context).size.width * 0.15;
    late EdgeInsetsGeometry bubblePadding = widget.isSentByMe ? EdgeInsets.fromLTRB(longPadding, 5, 10, 5) : EdgeInsets.fromLTRB(10, 5, longPadding, 5);
    late EdgeInsetsGeometry containerPadding = widget.isSentByMe ? const EdgeInsets.fromLTRB(10, 10, 15, 15) : const EdgeInsets.fromLTRB(15, 10, 10, 15);

    void onDelete() async {
      //后续还要修改，这里只写了动画
      await slideOutAnimationController.forward();
      await disappearAnimationController.forward();
      setState(() {
        widget.message.isDeleted = true;
      });
    }

    void onRecall() async {
      //后续还要修改，这里只写了动画
      await slideOutAnimationController.forward();
      await disappearAnimationController.forward();
      setState(() {
        shouldPlayRecallAnimation = true;
        widget.message.isRecalled = true;
        appearAnimationController.forward();
      });
    }

    final ContextMenuButtonItem forwardButton = ContextMenuButtonItem(
      label: '转发',
      onPressed: () {
        ContextMenuController.removeAny();
      },
    );
    final ContextMenuButtonItem quoteButton = ContextMenuButtonItem(
      label: '回复',
      onPressed: () {
        ContextMenuController.removeAny();
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
            });
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

    Widget getRepliedMessageContent(int messageReplied) {
      //后续改成从数据库获取
      final CommonMessage repliedMessage = CommonMessage(
          id: 2,
          chatId: 1,
          senderId: 10000000,
          receiverId: 1,
          createdTime: DateTime.now(),
          messageReplied: 1,
          sequence: 2,
          messageText: "你好，这里是被回复的消息",
          isImageMessage: true,
          messageImage: '["http://10.0.2.2:9000/user-avatar/DefaultAvatar.jpg"]');
      //后续改成从数据库获取
      final BriefUserInformation sender = BriefUserInformation(uuid: repliedMessage.senderId, avatar: 'http://10.0.2.2:9000/user-avatar/DefaultAvatar.jpg', nickname: 'nickname',updatedTime: DateTime.now(),);

      List<Widget> getContent() {
        List<Widget> content = [];
        content.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sender.nickname,
                style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurface),
              ),
              Container(
                width: 5,
              ),
              Text(
                repliedMessage.createdTime.toString().substring(11, 16),
                style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        );
        content.add(
          Container(
            height: 2,
          ),
        );

        if (repliedMessage.isDeleted) {
          content.add(
            Text(
              '该消息已被删除',
              style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurface),
            ),
          );
          return content;
        }

        if (repliedMessage.isRecalled) {
          content.add(
            Text(
              '该消息已被撤回',
              style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurface),
            ),
          );
          return content;
        }

        if (repliedMessage.isImageMessage) {
          List<dynamic> images = jsonDecode(repliedMessage.messageImage!);
          for (String image in images) {
            content.add(
              MessageImage(widget.bubbleHelper.removeContextMenu, image),
            );
          }
        }

        if (repliedMessage.messageText != null && repliedMessage.messageText!.isNotEmpty) {
          content.add(
            Text(
              repliedMessage.messageText!,
              maxLines: null,
              style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurface),
            ),
          );
        }

        return content;
      }

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

    //后续再做修改
    List<Widget> getMessageContent() {
      List<Widget> messageContent = [];

      if (widget.message.isReply) {
        messageContent.add(getRepliedMessageContent(widget.message.messageReplied!));
      }

      if (widget.message.isImageMessage) {
        List<dynamic> images = jsonDecode(widget.message.messageImage!);
        for (String image in images) {
          messageContent.add(
            MessageImage(widget.bubbleHelper.removeContextMenu, image),
          );
        }
      }

      if (widget.message.messageText != null && widget.message.messageText!.isNotEmpty) {
        messageContent.add(
          SelectableText(
            widget.message.messageText!,
            style: bubbleTextStyle,
            maxLines: null,
            contextMenuBuilder: selectableTextContextMenuBuilder,
          ),
        );
      }

      return messageContent;
    }

    late Widget bubbleContent = Flexible(
      child: Column(
        crossAxisAlignment: widget.isSentByMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
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
            child: Text(
              //待调整
              widget.message.createdTime.toString().substring(11, 16),
              style: Theme.of(context).textTheme.labelSmall!.apply(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ],
      ),
    );

    List<Widget> getWidgets() {
      List<Widget> widgets = [];
      if (widget.isSentByMe) {
        widgets.add(bubbleContent);
        widgets.add(Container(
          width: 10,
        ));
        widgets.add(Avatar(widget.sender.avatar));
      } else {
        widgets.add(Avatar(widget.sender.avatar));
        widgets.add(Container(
          width: 10,
        ));
        widgets.add(bubbleContent);
      }
      return widgets;
    }

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
        child: Container(
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

class MessageImage extends StatelessWidget {
  final void Function() removeContextMenu;
  final String image;
  final String heroTag = DateTime.now().toString();

  MessageImage(this.removeContextMenu, this.image, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        removeContextMenu();
        Navigator.pushNamed(
          context,
          '/view/image',
          arguments: {
            "heroTag": heroTag,
            "image": image,
          },
        );
      },
      child: Hero(
        tag: heroTag,
        child: CachedNetworkImage(
          fadeInDuration: const Duration(milliseconds: 800),
          fadeOutDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => const CupertinoActivityIndicator(),
          imageUrl: image,
          imageBuilder: (context, imageProvider) => Container(
            margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
              maxHeight: MediaQuery.of(context).size.width * 0.75,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                fit: BoxFit.cover,
                image: imageProvider,
              ),
            ),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error_outline),
        ),
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

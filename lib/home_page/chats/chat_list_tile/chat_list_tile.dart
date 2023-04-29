import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'models/brief_chat_target_information.dart';
import 'models/chat_list_tile_data.dart';


class ChatListTile extends StatefulWidget {
  final ChatListTileData chatListTileData;

  const ChatListTile({super.key, required this.chatListTileData});

  @override
  State<ChatListTile> createState() => _ChatListTileState();
}

class _ChatListTileState extends State<ChatListTile> with TickerProviderStateMixin {
  final ScrollController _controller = ScrollController();
  late double screenWidth = MediaQuery.of(context).size.width;
  final double tileHeight = 72;
  final double menuItemWidth = 84;
  final double menuItemHeight = 72;
  late bool shouldAbsorb = false;
  late bool isDeleted = false;

  void expandMenu() {
    _controller.animateTo(menuItemWidth * 2, duration: const Duration(milliseconds: 100), curve: Curves.linear);
    setState(() {
      shouldAbsorb = true;
    });
  }

  void recallMenu() {
    _controller.animateTo(0, duration: const Duration(milliseconds: 100), curve: Curves.linear);
    setState(() {
      shouldAbsorb = false;
    });
  }

  late AnimationController fadeOutAnimationController;
  late Animation<double> fadeOutAnimation;

  late AnimationController deleteAnimationController;
  late Animation<double> deleteAnimation;

  void deleteTile() async {
    await fadeOutAnimationController.forward();
    setState(() {
      isDeleted = true;
      deleteAnimationController.forward();
    });
  }

  late BriefChatTargetInformation chatTarget = BriefChatTargetInformation(
    targetType: widget.chatListTileData.briefChatTargetInformation.targetType,
    id:widget.chatListTileData.briefChatTargetInformation.id,
    avatar: widget.chatListTileData.briefChatTargetInformation.avatar,
    name: widget.chatListTileData.briefChatTargetInformation.name,
    updatedTime: widget.chatListTileData.briefChatTargetInformation.updatedTime,
  );

  @override
  void initState() {
    super.initState();

    fadeOutAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    fadeOutAnimation = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: fadeOutAnimationController, curve: Curves.easeOut),
    );

    deleteAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    deleteAnimation = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: deleteAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    fadeOutAnimationController.dispose();
    deleteAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isDeleted
        ? SizeTransition(
            axis: Axis.vertical,
            sizeFactor: deleteAnimation,
            child: SizedBox(
              height: tileHeight,
              width: double.infinity,
            ),
          )
        : FadeTransition(
            opacity: fadeOutAnimation,
            child: Listener(
              onPointerUp: (details) {
                if (_controller.offset < menuItemWidth) {
                  recallMenu();
                } else {
                  expandMenu();
                }
              },
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                controller: _controller,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_controller.offset != 0) {
                          recallMenu();
                        }
                      },
                      child: SizedBox(
                        width: screenWidth,
                        height: tileHeight,
                        child: AbsorbPointer(
                          absorbing: shouldAbsorb,
                          //后面再调，还没写群组、系统以及时间显示
                          child: ListTile(
                            leading: Avatar(chatTarget.avatar),
                            title: Text(
                              chatTarget.name,
                              style: Theme.of(context).textTheme.bodyLarge?.apply(color: Theme.of(context).colorScheme.onSurface),
                            ),
                            subtitle: Text(
                              widget.chatListTileData.messagePreview??'',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.apply(color: Theme.of(context).colorScheme.outline),
                            ),
                            trailing: Text(
                                widget.chatListTileData.lastMessageCreatedTime?.toString().substring(11, 16)??'',
                              style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                            ),
                            onTap: () {
                              Navigator.pushNamed(context, '/chats/message/friend', arguments: chatTarget);
                            },
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        recallMenu();
                      },
                      child: Container(
                        width: menuItemWidth,
                        height: menuItemHeight,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Center(
                          child: Text(
                            '置顶',
                            style: Theme.of(context).textTheme.bodyLarge?.apply(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        recallMenu();
                        deleteTile();
                      },
                      child: Container(
                        width: menuItemWidth,
                        height: menuItemHeight,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Center(
                          child: Text(
                            '删除',
                            style: Theme.of(context).textTheme.bodyLarge?.apply(color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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

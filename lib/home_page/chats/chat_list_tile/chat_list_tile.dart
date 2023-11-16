import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/database/models/chat/chat.dart';
import 'package:meta_uni_app/database/models/user/user_sync_table.dart';
import 'package:meta_uni_app/reusable_components/formatter/date_time_formatter/date_time_formatter.dart';
import 'package:meta_uni_app/reusable_components/rich_text_with_sticker/rich_text_with_sticker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../bloc/bloc_manager.dart';
import '../../../bloc/chat_list_tile/models/chat_list_tile_update_data.dart';
import '../../../database/database_manager.dart';
import '../../../models/dio_model.dart';
import '../../../reusable_components/logout/logout.dart';
import '../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../reusable_components/snack_bar/normal_snack_bar.dart';
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

  changeChatStickyStatus(bool isStickyOnTop, DateTime updatedTime, int uuid) async {
    Database database = await DatabaseManager().getDatabase;
    ChatProvider chatProvider = ChatProvider(database);

    UserSyncTableProvider userSyncTableProvider = UserSyncTableProvider(database);

    chatProvider.changeStickyStatus(isStickyOnTop, widget.chatListTileData.chatId);
    userSyncTableProvider.update({
      'updatedTimeForChats': updatedTime.millisecondsSinceEpoch,
    }, uuid);
  }

  onChangeChatStickyStatus() async {
    DioModel dioModel = DioModel();

    final prefs = await SharedPreferences.getInstance();
    int uuid = prefs.getInt('uuid')!;
    String jwt = prefs.getString('jwt')!;

    try {
      Response response;
      response = await dioModel.dio.put(
        '/metaUni/messageAPI/chat/stickyOnTop/${widget.chatListTileData.chatId}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          await changeChatStickyStatus(
            response.data['data']['isStickyOnTop'],
            DateTime.parse(
              response.data['data']['updatedTime'],
            ),
            uuid,
          );
          BlocManager().chatListTileDataCubit.shouldUpdate(
                ChatListTileUpdateData(chatId: widget.chatListTileData.chatId),
              );
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
        //Message:"目标对话不存在"
        case 3:
          //Message:"您无法对不属于您的对话进行该操作"
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

  deleteChat(DateTime updatedTime, int uuid) async {
    Database database = await DatabaseManager().getDatabase;
    ChatProvider chatProvider = ChatProvider(database);

    UserSyncTableProvider userSyncTableProvider = UserSyncTableProvider(database);
    chatProvider.delete(widget.chatListTileData.chatId);

    userSyncTableProvider.update({
      'updatedTimeForChats': updatedTime.millisecondsSinceEpoch,
    }, uuid);
  }

  void deleteTile() {
    fadeOutAnimationController.forward().then((value) => {deleteAnimationController.forward()});
  }

  void onDelete() async {
    DioModel dioModel = DioModel();

    final prefs = await SharedPreferences.getInstance();
    int uuid = prefs.getInt('uuid')!;
    String jwt = prefs.getString('jwt')!;

    try {
      Response response;
      response = await dioModel.dio.delete(
        '/metaUni/messageAPI/chat/${widget.chatListTileData.chatId}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          await deleteChat(DateTime.parse(response.data['data']['updatedTime']), uuid);
          BlocManager().totalNumberOfUnreadMessagesCubit.decrement(widget.chatListTileData.numberOfUnreadMessages);
          deleteTile();
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
        //Message:"目标对话不存在"
        case 3:
          //Message:"您无法对不属于您的对话进行删除操作"
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

  late BriefChatTargetInformation chatTarget = BriefChatTargetInformation(
    chatId: widget.chatListTileData.chatId,
    targetType: widget.chatListTileData.briefChatTargetInformation.targetType,
    id: widget.chatListTileData.briefChatTargetInformation.id,
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
  void didUpdateWidget(covariant ChatListTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    chatTarget = BriefChatTargetInformation(
      chatId: widget.chatListTileData.chatId,
      targetType: widget.chatListTileData.briefChatTargetInformation.targetType,
      id: widget.chatListTileData.briefChatTargetInformation.id,
      avatar: widget.chatListTileData.briefChatTargetInformation.avatar,
      name: widget.chatListTileData.briefChatTargetInformation.name,
      updatedTime: widget.chatListTileData.briefChatTargetInformation.updatedTime,
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
    return SizeTransition(
      axis: Axis.vertical,
      sizeFactor: deleteAnimation,
      child: FadeTransition(
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
                  child: Container(
                    width: screenWidth,
                    height: tileHeight,
                    color: widget.chatListTileData.isStickyOnTop ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6) : Theme.of(context).colorScheme.surface,
                    child: AbsorbPointer(
                      absorbing: shouldAbsorb,
                      //后面再调，还没写群组
                      child: ListTile(
                        leading: Avatar(chatTarget.avatar),
                        title: Text(
                          chatTarget.name,
                          style: Theme.of(context).textTheme.bodyLarge?.apply(color: Theme.of(context).colorScheme.onSurface),
                        ),
                        subtitle: RichTextWithSticker(
                          text: widget.chatListTileData.messagePreview ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textStyle: Theme.of(context).textTheme.bodyMedium?.apply(color: Theme.of(context).colorScheme.outline),
                        ),
                        trailing: widget.chatListTileData.numberOfUnreadMessages == 0
                            ? Text(
                                widget.chatListTileData.lastMessageCreatedTime == null ? '' : getFormattedDateTime(dateTime: widget.chatListTileData.lastMessageCreatedTime!),
                                style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.outline),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    widget.chatListTileData.lastMessageCreatedTime == null ? '' : getFormattedDateTime(dateTime: widget.chatListTileData.lastMessageCreatedTime!),
                                    style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.outline),
                                  ),
                                  Badge(
                                    label: Text(widget.chatListTileData.numberOfUnreadMessages > 99 ? "99+" : widget.chatListTileData.numberOfUnreadMessages.toString()),
                                  ),
                                ],
                              ),
                        onTap: () {
                          if(widget.chatListTileData.briefChatTargetInformation.targetType == "user")
                          {
                            Navigator.pushNamed(context, '/chats/message/friend', arguments: chatTarget);
                          }
                          else if(widget.chatListTileData.briefChatTargetInformation.targetType == "system")
                          {
                            Navigator.pushNamed(context, '/chats/message/system', arguments: chatTarget);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    recallMenu();
                    onChangeChatStickyStatus();
                  },
                  child: Container(
                    width: menuItemWidth,
                    height: menuItemHeight,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Center(
                      child: Text(
                        widget.chatListTileData.isStickyOnTop ? '取消置顶' : '置顶',
                        style: Theme.of(context).textTheme.bodyLarge?.apply(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    recallMenu();
                    onDelete();
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

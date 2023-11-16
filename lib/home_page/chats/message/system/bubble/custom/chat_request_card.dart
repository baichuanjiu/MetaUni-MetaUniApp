import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/database/database_manager.dart';
import 'package:meta_uni_app/database/models/user/brief_user_information.dart';
import 'package:meta_uni_app/reusable_components/send_auto_text_message/send_auto_text_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../../../models/dio_model.dart';
import '../../../../../../reusable_components/logout/logout.dart';
import '../../../../../../reusable_components/rich_text_with_sticker/rich_text_with_sticker.dart';
import '../../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../../reusable_components/snack_bar/normal_snack_bar.dart';

class ChatRequestCardData {
  late int sender;
  late String greetText;

  ChatRequestCardData.fromJson(Map<String, dynamic> map) {
    sender = map['sender'];
    greetText = map['greetText'];
  }
}

class ChatRequestCard extends StatefulWidget {
  final ChatRequestCardData chatRequestCardData;
  final Function(TapDownDetails details) setContextMenuAnchor;
  final Function showDeleteContextMenu;

  const ChatRequestCard({super.key, required this.chatRequestCardData, required this.setContextMenuAnchor, required this.showDeleteContextMenu});

  @override
  State<ChatRequestCard> createState() => _ChatRequestCardState();
}

class _ChatRequestCardState extends State<ChatRequestCard> {
  BriefUserInformation? senderInfo;
  late Future<dynamic> init;
  late int uuid;
  late String jwt;

  final DioModel dioModel = DioModel();
  late final BriefUserInformationProvider briefUserInformationProvider;

  late Database database;

  getBriefUserInformation(int queryUUID) async {
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

  _init() async {
    database = await DatabaseManager().getDatabase;
    final prefs = await SharedPreferences.getInstance();

    jwt = prefs.getString('jwt')!;
    uuid = prefs.getInt('uuid')!;

    briefUserInformationProvider = BriefUserInformationProvider(database);

    senderInfo = await briefUserInformationProvider.get(widget.chatRequestCardData.sender);
    if (senderInfo == null) {
      await getBriefUserInformation(widget.chatRequestCardData.sender);
      senderInfo = await briefUserInformationProvider.get(widget.chatRequestCardData.sender);
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    init = _init();
  }

  blockAnyway() async {
    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/userAPI/user/block/blockAnyway/${senderInfo!.uuid}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          //Message:"已屏蔽该用户"
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
        //Message:"您无法对不存在的用户进行此操作"
        case 3:
          //Message:"您无法对自己进行此操作"
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 5, 0, 10),
      width: MediaQuery.of(context).size.width * 0.9,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTapDown: (details) {
          widget.setContextMenuAnchor(details);
        },
        onLongPress: () {
          widget.showDeleteContextMenu();
        },
        child: Card(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                senderInfo == null
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
                        child: Text(
                          "一条私聊请求",
                          maxLines: null,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(15, 5, 5, 5),
                        child: Row(
                          children: [
                            CachedNetworkImage(
                              fadeInDuration: const Duration(milliseconds: 800),
                              fadeOutDuration: const Duration(milliseconds: 200),
                              placeholder: (context, url) => const CupertinoActivityIndicator(),
                              imageUrl: senderInfo!.avatar,
                              imageBuilder: (context, imageProvider) => CircleAvatar(
                                radius: 20,
                                backgroundImage: imageProvider,
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                            ),
                            Container(
                              width: 15,
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: senderInfo!.nickname,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    TextSpan(
                                      text: " 向您发送了私聊请求",
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PopupMenuButton(
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem(
                                    onTap: () {
                                      blockAnyway();
                                    },
                                    child: const ListTile(
                                      leading: Icon(
                                        Icons.notifications_off,
                                      ),
                                      title: Text('屏蔽此人'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    onTap: () {
                                      Navigator.pushNamed(context, '/user/profile', arguments: senderInfo!.uuid);
                                    },
                                    child: const ListTile(
                                      leading: Icon(
                                        Icons.account_circle,
                                      ),
                                      title: Text('查看个人资料'),
                                    ),
                                  ),
                                ];
                              },
                              offset: const Offset(0, 56),
                              tooltip: '快捷操作',
                              icon: Icon(
                                Icons.more_vert_outlined,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                  child: RichTextWithSticker(
                    text: widget.chatRequestCardData.greetText,
                    maxLines: null,
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: senderInfo == null
                            ? null
                            : () async {
                                if (await sendAutoTextMessage(senderInfo!.uuid, "我已同意你的私聊请求", jwt, uuid, context)) {
                                  if (mounted) {
                                    getNormalSnackBar(context, "您已同意该私聊请求");
                                  }
                                }
                              },
                        child: const Text("同意"),
                      ),
                    ],
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

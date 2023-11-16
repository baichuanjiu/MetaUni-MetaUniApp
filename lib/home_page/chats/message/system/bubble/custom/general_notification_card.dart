import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/reusable_components/rich_text_with_sticker/rich_text_with_sticker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../database/models/mini_app/brief_mini_app_information.dart';
import '../../../../../../models/dio_model.dart';
import '../../../../../../reusable_components/logout/logout.dart';
import '../../../../../../reusable_components/open_mini_app/open_mini_app.dart';
import '../../../../../../reusable_components/snack_bar/normal_snack_bar.dart';

class Content {
  late String key;
  late String value;

  Content.fromJson(Map<String, dynamic> map) {
    key = map['key'];
    value = map['value'];
  }
}

class GeneralNotificationCardData {
  late String title;
  late String description;
  late List<Content> contents;
  late String? openPageUrl;
  late String? openPageText;
  late String? miniAppId;

  GeneralNotificationCardData.fromJson(Map<String, dynamic> map) {
    title = map['title'];
    description = map['description'];
    contents = [];
    for (var content in map['contents']) {
      contents.add(Content.fromJson(content));
    }
    openPageUrl = map['openPageUrl'];
    openPageText = map['openPageText'];
    miniAppId = map['miniAppId'];
  }
}

class GeneralNotificationCard extends StatefulWidget {
  final GeneralNotificationCardData generalNotificationCardData;
  final String? miniAppId;
  final Function(TapDownDetails details) setContextMenuAnchor;
  final Function showDeleteContextMenu;

  const GeneralNotificationCard({super.key, required this.generalNotificationCardData, this.miniAppId, required this.setContextMenuAnchor, required this.showDeleteContextMenu});

  @override
  State<GeneralNotificationCard> createState() => _GeneralNotificationCardState();
}

class _GeneralNotificationCardState extends State<GeneralNotificationCard> {
  Future<BriefMiniAppInformation?> getBriefMiniAppInfo(String id) async {
    DioModel dioModel = DioModel();

    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    BriefMiniAppInformation? info;

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/miniAppAPI/miniApp/briefInfo/$id',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          info = BriefMiniAppInformation.fromJson(response.data['data']);
          return info;
        //break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (context.mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          return null;
        //break;
        case 2:
          //Message:"您正在尝试打开不存在的MiniApp"
          if (context.mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          return null;
        //break;
        default:
          if (context.mounted) {
            return null;
          }
        //break;
      }
    } catch (e) {
      if (context.mounted) {
        return null;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> contents = [];
    for (var content in widget.generalNotificationCardData.contents) {
      contents.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "${content.key}    ",
                  style: Theme.of(context).textTheme.bodyMedium?.apply(color: Theme.of(context).colorScheme.outline),
                ),
                TextSpan(
                  text: content.value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            maxLines: null,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 5, 0, 10),
      width: MediaQuery.of(context).size.width * 0.9,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTapDown: (details) {
          widget.setContextMenuAnchor(details);
        },
        onTap: widget.generalNotificationCardData.openPageUrl == null
            ? null
            : () async {
                if (widget.generalNotificationCardData.miniAppId != null) {
                  BriefMiniAppInformation? miniApp = await getBriefMiniAppInfo(widget.generalNotificationCardData.miniAppId!);
                  if (miniApp != null) {
                    if (mounted) {
                      if (miniApp.type == 'ClientApp' && miniApp.minimumSupportVersion != null) {
                        openClientApp(miniApp.id, widget.generalNotificationCardData.openPageUrl!, miniApp.minimumSupportVersion!, context);
                      } else if (miniApp.type == 'WebApp' && miniApp.url != null) {
                        openWebApp(miniApp.id, widget.generalNotificationCardData.openPageUrl!, miniApp.name, context);
                      }
                    }
                  }
                }
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: Text(
                    widget.generalNotificationCardData.title,
                    maxLines: null,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 10),
                  child: RichTextWithSticker(
                    text: widget.generalNotificationCardData.description,
                    maxLines: null,
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                contents.isEmpty
                    ? Container()
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: contents,
                        ),
                      ),
                widget.generalNotificationCardData.openPageUrl == null
                    ? Container()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.generalNotificationCardData.openPageText ?? "查看详情",
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_outlined,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

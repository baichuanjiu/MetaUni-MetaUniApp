import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/reusable_components/rich_text_with_sticker/rich_text_with_sticker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../database/models/mini_app/brief_mini_app_information.dart';
import '../../../../../models/dio_model.dart';
import '../../../../../reusable_components/logout/logout.dart';
import '../../../../../reusable_components/open_mini_app/open_mini_app.dart';
import '../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../models/feed_data.dart';

class FeedCard extends StatefulWidget {
  final FeedData data;

  const FeedCard({super.key, required this.data});

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
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

  readFeed() async {
    DioModel dioModel = DioModel();

    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/feedAPI/feed/read/${widget.data.id}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (context.mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        default:
          if (context.mounted) {
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if (context.mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        readFeed();
        BriefMiniAppInformation? miniApp = await getBriefMiniAppInfo(widget.data.briefMiniAppInfo.id);
        if (miniApp != null) {
          if (mounted) {
            if (miniApp.type == 'ClientApp' && miniApp.minimumSupportVersion != null) {
              openClientApp(widget.data.briefMiniAppInfo.id, widget.data.openPageUrl, miniApp.minimumSupportVersion!, context);
            } else if (miniApp.type == 'WebApp' && miniApp.url != null) {
              openWebApp(widget.data.briefMiniAppInfo.id, widget.data.openPageUrl, widget.data.briefMiniAppInfo.name, context);
            }
          }
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.data.cover == null
                ? Container()
                : widget.data.cover!.type == "video"
                    ? AspectRatio(
                        aspectRatio: widget.data.cover!.aspectRatio,
                        child: CachedNetworkImage(
                          fadeInDuration: const Duration(milliseconds: 800),
                          fadeOutDuration: const Duration(milliseconds: 200),
                          placeholder: (context, url) => const CupertinoActivityIndicator(),
                          imageUrl: widget.data.cover!.previewImage!,
                          imageBuilder: (context, imageProvider) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  left: 10,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                                    ),
                                    child: Text(
                                      formatTime(widget.data.cover!.timeTotal!),
                                      style: Theme.of(context).textTheme.labelLarge?.apply(
                                            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                        ),
                      )
                    : AspectRatio(
                        aspectRatio: widget.data.cover!.aspectRatio,
                        child: CachedNetworkImage(
                          fadeInDuration: const Duration(milliseconds: 800),
                          fadeOutDuration: const Duration(milliseconds: 200),
                          placeholder: (context, url) => const CupertinoActivityIndicator(),
                          imageUrl: widget.data.cover!.url,
                          imageBuilder: (context, imageProvider) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                        ),
                      ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 6, 5, 2),
              child: RichTextWithSticker(
                text: widget.data.previewContent,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 6, 0, 4),
              child: Row(
                children: [
                  Column(
                    children: [
                      Avatar(widget.data.briefMiniAppInfo.avatar),
                      Text(
                        widget.data.briefMiniAppInfo.name,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  Container(
                    width: 5,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          widget.data.title,
                          style: Theme.of(context).textTheme.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          height: 2,
                        ),
                        Text(
                          widget.data.description,
                          style: Theme.of(context).textTheme.bodySmall?.apply(color: Theme.of(context).colorScheme.outline),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.more_horiz_outlined,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      placeholder: (context, url) => CircleAvatar(
        radius: 15,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const CupertinoActivityIndicator(),
      ),
      imageUrl: avatar,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 15,
        backgroundImage: imageProvider,
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: 15,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.error_outline),
      ),
    );
  }
}

String formatTime(Duration time) {
  if (time.inHours < 1) {
    return time.toString().substring(2, 7);
  } else {
    int digit = 0;
    double number = time.inHours.toDouble();
    while (number >= 1) {
      digit++;
      number = (number / 10);
    }
    return time.toString().substring(0, 6 + digit);
  }
}

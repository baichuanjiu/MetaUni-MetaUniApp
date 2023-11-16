import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../../../../../reusable_components/formatter/date_time_formatter/date_time_formatter.dart';
import '../../../../../../reusable_components/logout/logout.dart';
import '../../../../../../reusable_components/media/models/view_media_metadata.dart';
import '../../../../../../reusable_components/media/video/video_preview.dart';
import '../../../../../../reusable_components/media/view_media_page.dart';
import '../../../../../../reusable_components/route_animation/route_animation.dart';
import '../../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../../mini_app_manager.dart';
import '../models/mission_data.dart';

class MissionDetailsPage extends StatefulWidget {
  final String id;

  const MissionDetailsPage({super.key, required this.id});

  @override
  State<MissionDetailsPage> createState() => _MissionDetailsPageState();
}

class _MissionDetailsPageState extends State<MissionDetailsPage> {
  late MissionData missionData;
  bool hasGotData = false;

  late final Dio dio;

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  late final String? jwt;
  late final int? uuid;

  late Future<dynamic> init;

  _init() async {
    await _initDio();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    jwt = prefs.getString('jwt');
    uuid = prefs.getInt('uuid');

    await getMissionDetails();
  }

  getMissionDetails() async {
    try {
      Response response;
      response = await dio.get(
        '/fleaMarket/marketAPI/mission/details/${widget.id}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          missionData = MissionData.fromJson(response.data['data']['data']);
          hasGotData = true;
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
          //Message:"您正在对不存在或已删除的数据进行查询"
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
  void initState() {
    super.initState();

    init = _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("详情"),
        centerTitle: true,
      ),
      body: FutureBuilder(
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
              if (!hasGotData) {
                return const Center(
                  child: CupertinoActivityIndicator(),
                );
              }
              Widget price;
              switch (missionData.priceData.type) {
                case "accurate":
                  price = Text(
                    "￥${missionData.priceData.price!.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.bodyLarge?.apply(
                          color: Colors.orange,
                        ),
                  );
                  break;
                case "range":
                  price = Text(
                    "￥${missionData.priceData.priceRange!.start.toStringAsFixed(2)} ~ ${missionData.priceData.priceRange!.end.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.bodyLarge?.apply(
                          color: Colors.orange,
                        ),
                  );
                  break;
                default:
                  price = Text(
                    "￥待定",
                    style: Theme.of(context).textTheme.bodyLarge?.apply(
                          color: Colors.orange,
                        ),
                  );
                  break;
              }

              List<Widget> labels = [];
              missionData.labels.forEach((key, value) {
                labels.add(
                  Column(
                    children: [
                      Text(
                        key,
                        style: Theme.of(context).textTheme.bodyMedium?.apply(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
                labels.add(
                  const VerticalDivider(),
                );
              });
              if (labels.isNotEmpty) {
                labels.removeLast();
              }

              List<ViewMediaMetadata> viewMediaMetadataList = [];
              List<Widget> mediaList = [];
              int currentIndex = 0;
              for (var media in missionData.medias) {
                String heroTag = DateTime.now().microsecondsSinceEpoch.toString();
                if (media.type == "image") {
                  viewMediaMetadataList.add(
                    ViewMediaMetadata(type: "image", heroTag: heroTag, imageURL: media.url),
                  );
                  int index = currentIndex;
                  mediaList.add(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
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
                                ),
                                opaque: false,
                              ),
                            );
                          },
                          child: Hero(
                            tag: heroTag,
                            child: CachedNetworkImage(
                              fadeInDuration: const Duration(milliseconds: 800),
                              fadeOutDuration: const Duration(milliseconds: 200),
                              placeholder: (context, url) => const CupertinoActivityIndicator(),
                              imageUrl: media.url,
                              imageBuilder: (context, imageProvider) => Image(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error_outline),
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
                  mediaList.add(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
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

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: CachedNetworkImage(
                              fadeInDuration: const Duration(milliseconds: 800),
                              fadeOutDuration: const Duration(milliseconds: 200),
                              placeholder: (context, url) => CircleAvatar(
                                radius: 25,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                child: const CupertinoActivityIndicator(),
                              ),
                              imageUrl: missionData.user.avatar,
                              imageBuilder: (context, imageProvider) => CircleAvatar(
                                radius: 25,
                                backgroundImage: imageProvider,
                              ),
                              errorWidget: (context, url, error) => CircleAvatar(
                                radius: 25,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                child: const Icon(Icons.error_outline),
                              ),
                            ),
                            title: Text(missionData.user.nickname),
                            trailing: Text(missionData.type == "purchase" ? "求购" : "出售"),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                            child: SelectableText(
                              missionData.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                            child: SelectableText(
                              missionData.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          missionData.campus == null
                              ? Container()
                              : Padding(
                                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                                      color: Theme.of(context).colorScheme.secondaryContainer,
                                      child: Text(
                                        missionData.campus!,
                                        style: Theme.of(context).textTheme.bodyMedium?.apply(
                                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                          missionData.labels.isEmpty
                              ? Container()
                              : Padding(
                                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                                  child: Wrap(
                                    children: labels,
                                  ),
                                ),
                          Column(
                            children: [
                              ...mediaList,
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "发布于 ${getFormattedDateTime(dateTime: missionData.createdTime)}",
                                  style: Theme.of(context).textTheme.bodyMedium?.apply(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          price,
                          ElevatedButton.icon(
                            onPressed: () {
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
                                                  "向 ",
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
                                                    imageUrl: missionData.user.avatar,
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
                                                    " ${missionData.user.nickname} 发送私聊请求",
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
                                                            "打个招呼：",
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
                                                      onPressed: () async {
                                                        try {
                                                          Response response;
                                                          response = await dio.post(
                                                            '/fleaMarket/marketAPI/user/chatRequest',
                                                            data: {
                                                              'title': missionData.title,
                                                              'targetUser': missionData.user.uuid,
                                                              'greetText': textController.text,
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
                                                            //Message:"发送私聊请求失败，您无法向自己发送私聊请求"
                                                            case 3:
                                                            //Message:"发送私聊请求失败，您向该用户发送私聊请求的操作太过频繁"
                                                            case 4:
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
                                                        if (mounted) {
                                                          Navigator.pop(context);
                                                        }
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
                            },
                            icon: const Icon(
                              Icons.question_answer_outlined,
                            ),
                            label: const Text("聊聊看"),
                          ),
                        ],
                      ),
                    ),
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
    );
  }
}

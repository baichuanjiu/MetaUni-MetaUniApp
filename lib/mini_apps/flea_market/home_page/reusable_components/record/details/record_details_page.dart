import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import '../models/record_data.dart';

class RecordDetailsPage extends StatefulWidget {
  final String id;

  const RecordDetailsPage({super.key, required this.id});

  @override
  State<RecordDetailsPage> createState() => _RecordDetailsPageState();
}

class _RecordDetailsPageState extends State<RecordDetailsPage> {
  late RecordData recordData;
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

    await getRecordDetails();
  }

  getRecordDetails() async {
    try {
      Response response;
      response = await dio.get(
        '/fleaMarket/marketAPI/record/details/${widget.id}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          recordData = RecordData.fromJson(response.data['data']['data']);
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

              List<Widget> labels = [];
              recordData.labels.forEach((key, value) {
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
              for (var media in recordData.medias) {
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
                              imageUrl: recordData.user.avatar,
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
                            title: Text(recordData.user.nickname),
                            trailing: Text(recordData.type == "purchase" ? "求购" : "出售"),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                            child: SelectableText(
                              recordData.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                            child: SelectableText(
                              recordData.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          recordData.campus == null
                              ? Container()
                              : Padding(
                                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                                      color: Theme.of(context).colorScheme.secondaryContainer,
                                      child: Text(
                                        recordData.campus!,
                                        style: Theme.of(context).textTheme.bodyMedium?.apply(
                                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                          recordData.labels.isEmpty
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
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "成交价格：",
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  TextSpan(
                                    text: "￥${recordData.price.toStringAsFixed(2)}",
                                    style: Theme.of(context).textTheme.bodyMedium?.apply(
                                          color: Colors.orange,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "备注：",
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  TextSpan(
                                    text: recordData.remark,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "成交于 ${getFormattedDateTime(dateTime: recordData.createdTime)}",
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

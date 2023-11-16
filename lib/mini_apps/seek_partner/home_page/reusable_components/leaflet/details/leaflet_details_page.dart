import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/reusable_components/leaflet/details/label/labels.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/reusable_components/leaflet/details/medias/nine_box_grid.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/reusable_components/user_card/card/user_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../reusable_components/formatter/date_time_formatter/date_time_formatter.dart';
import '../../../../../../reusable_components/logout/logout.dart';
import '../../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../../mini_app_manager.dart';
import '../../tag/tags.dart';
import '../../user_card/models/user_card_data.dart';
import '../models/leaflet_data.dart';

class LeafletDetailsPage extends StatefulWidget {
  final String id;

  const LeafletDetailsPage({super.key, required this.id});

  @override
  State<LeafletDetailsPage> createState() => _LeafletDetailsPageState();
}

class _LeafletDetailsPageState extends State<LeafletDetailsPage> {
  late LeafletData leafletData;
  late UserCardData userCardData;
  bool hasGotData = false;

  bool isDock = true;
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

    await getLeafletDetails();
  }

  getLeafletDetails() async {
    try {
      Response response;
      response = await dio.get(
        '/seekPartner/leafletAPI/leaflet/details/${widget.id}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          leafletData = LeafletData.fromJson(response.data['data']['leaflet']);
          userCardData = UserCardData.fromJson(response.data['data']['userCard']);
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
        //Message:"您正在对一个不存在的搭搭请求进行查询"
        case 3:
          //Message:"您正在对一个已失效的搭搭请求进行查询"
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
              return Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      leafletData.title,
                                      style: Theme.of(context).textTheme.titleLarge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    leafletData.channel,
                                    style: Theme.of(context).textTheme.labelLarge?.apply(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.75),
                                        ),
                                  ),
                                ],
                              ),
                              Container(
                                height: 10,
                              ),
                              SelectableText(
                                leafletData.description,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Labels(labels: leafletData.labels),
                              Tags(tags: leafletData.tags),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                                child: NineBoxGrid(medias: leafletData.medias),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: "截止时间  ",
                                              style: Theme.of(context).textTheme.labelMedium?.apply(
                                                    color: Theme.of(context).colorScheme.outline,
                                                  ),
                                            ),
                                            TextSpan(
                                              text: getFormattedDateTime(dateTime: leafletData.deadline, shouldShowTime: true),
                                              style: Theme.of(context).textTheme.labelMedium?.apply(
                                                    color: Theme.of(context).colorScheme.outline,
                                                  ),
                                            ),
                                          ],
                                        ),
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
                  ),
                  AnimatedPositioned(
                    width: MediaQuery.of(context).size.width,
                    right: isDock ? -(MediaQuery.of(context).size.width - 80) : 0,
                    bottom: 5,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isDock = !isDock;
                        });
                      },
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null) {
                          if (details.primaryVelocity!.isNegative) {
                            setState(() {
                              isDock = false;
                            });
                          } else {
                            setState(() {
                              isDock = true;
                            });
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: Column(
                          children: [
                            UserCard(
                              data: userCardData,
                            ),
                            ElevatedButton(
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
                                                      imageUrl: userCardData.user.avatar,
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
                                                      " ${userCardData.user.nickname} 发送私聊请求",
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
                                                              '/seekPartner/leafletAPI/user/chatRequest',
                                                              data: {
                                                                'title': leafletData.title,
                                                                'targetUser': userCardData.user.uuid,
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
                                                            setState(() {
                                                              isDock = true;
                                                            });
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
                              child: const Text("私聊"),
                            ),
                          ],
                        ),
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

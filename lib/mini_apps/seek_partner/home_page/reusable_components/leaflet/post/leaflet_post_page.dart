import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../../../reusable_components/logout/logout.dart';
import '../../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../../mini_app_manager.dart';
import '../details/leaflet_details_page.dart';

class LeafletPostPage extends StatefulWidget {
  final String title;
  final String description;
  final Map<String, String> labels;
  final List<String> tags;
  final List<File> medias;

  const LeafletPostPage({
    super.key,
    required this.title,
    required this.description,
    required this.labels,
    required this.tags,
    required this.medias,
  });

  @override
  State<LeafletPostPage> createState() => _LeafletPostPageState();
}

class _LeafletPostPageState extends State<LeafletPostPage> with TickerProviderStateMixin {
  String? channel;
  DateTime? date;
  TimeOfDay? time;

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

    await getChannelList();
  }

  final double _kItemExtent = 32.0;
  List<String>? channelList;
  int _selectedChannel = 0;

  getChannelList() async {
    try {
      Response response;
      response = await dio.get(
        '/seekPartner/leafletAPI/leaflet/channelList',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          var dataList = response.data['data'];
          channelList = [];
          for (var data in dataList) {
            channelList!.add(data);
          }
          channelList!.removeAt(0);
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
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

  bool isPosting = false;
  late AnimationController fadeAnimationController;
  late Animation<double> fadeAnimation;
  int fadeMilliseconds = 750;

  void postLeaflet() async {
    final deadline = date!.add(
      Duration(hours: time!.hour, minutes: time!.minute),
    );
    if (deadline.difference(DateTime.now()).inMinutes <= 35) {
      getNormalSnackBar(context, "截止时间与当前时间过近，请重新设置");
      return;
    }

    setState(() {
      isPosting = true;
      fadeAnimationController.forward();
    });

    Map<String, dynamic> formDataMap = {
      'title': widget.title,
      'description': widget.description,
      'labels': widget.labels,
      'tags': widget.tags,
      'channel': channel,
      'deadline': deadline,
    };

    for (int i = 0; i < widget.medias.length; i++) {
      List<String> mimeType = lookupMimeType(widget.medias[i].path)!.split('/');
      if (mimeType[0] == 'image') {
        var decodedImage = await decodeImageFromList(
          widget.medias[i].readAsBytesSync(),
        );
        final newEntries = {
          'medias[$i].File': await MultipartFile.fromFile(
            widget.medias[i].path,
            contentType: MediaType(
              mimeType[0],
              mimeType[1],
            ),
          ),
          'medias[$i].AspectRatio': decodedImage.width / decodedImage.height,
        };
        formDataMap.addEntries(newEntries.entries);
      }
    }

    try {
      Response response;
      var formData = FormData.fromMap(
        formDataMap,
        ListFormat.multiCompatible,
      );
      response = await dio.post(
        '/seekPartner/leafletAPI/leaflet',
        data: formData,
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          Future.delayed(Duration(milliseconds: fadeMilliseconds)).then((value) {
            fadeAnimationController.reverse().then((value) {
              setState(() {
                isPosting = false;
              });
              Navigator.popUntil(
                context,
                ModalRoute.withName('/miniApps/seekPartner'),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return LeafletDetailsPage(id: response.data['data']['id']);
                  },
                ),
              );
              getNormalSnackBar(context, response.data['message']);
            });
          });
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            Future.delayed(Duration(milliseconds: fadeMilliseconds)).then((value) {
              fadeAnimationController.reverse().then((value) {
                setState(() {
                  isPosting = false;
                });
                getNormalSnackBar(context, response.data['message']);
                logout(context);
              });
            });
          }
          break;
        case 2:
        //Message:"发布失败，标题或描述不允许为空"
        case 3:
        //Message:"发布失败，选择的截止时间距现在过短或过长"
        case 4:
        //Message:"发布失败，上传文件数超过限制"
        case 5:
          //Message:"发布失败，禁止上传规定格式以外的文件"
          if (mounted) {
            Future.delayed(Duration(milliseconds: fadeMilliseconds)).then((value) {
              fadeAnimationController.reverse().then((value) {
                setState(() {
                  isPosting = false;
                });
                getNormalSnackBar(context, response.data['message']);
              });
            });
          }
          break;
        case 6:
        //Message:"发生错误，发布失败"
        case 7:
          //Message:"发生错误，发布失败"
          if (mounted) {
            Future.delayed(Duration(milliseconds: fadeMilliseconds)).then((value) {
              fadeAnimationController.reverse().then((value) {
                setState(() {
                  isPosting = false;
                });
                getNetworkErrorSnackBar(context);
              });
            });
          }
          break;
        default:
          if (mounted) {
            Future.delayed(Duration(milliseconds: fadeMilliseconds)).then((value) {
              fadeAnimationController.reverse().then((value) {
                setState(() {
                  isPosting = false;
                });
                getNetworkErrorSnackBar(context);
              });
            });
          }
      }
    } catch (e) {
      if (mounted) {
        Future.delayed(Duration(milliseconds: fadeMilliseconds)).then((value) {
          fadeAnimationController.reverse().then((value) {
            setState(() {
              isPosting = false;
            });
            getNetworkErrorSnackBar(context);
          });
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    init = _init();

    fadeAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: fadeMilliseconds),
    );
    fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: fadeAnimationController, curve: Curves.ease),
    );
  }

  @override
  void dispose() {
    fadeAnimationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leadingWidth: 70,
            leading: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('上一步'),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                child: FilledButton.tonal(
                  onPressed: (channel == null || date == null || time == null)
                      ? null
                      : () {
                          postLeaflet();
                        },
                  child: const Text("发布"),
                ),
              ),
            ],
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
                  if (channelList == null || channelList!.isEmpty) {
                    return const Center(
                      child: CupertinoActivityIndicator(),
                    );
                  }
                  return Column(
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
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                child: Text(
                                  "推送频道",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                child: Text(
                                  "选择合适的推送频道，将有助于您的搭搭请求被志同道合的朋友们发现。",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        showDialog<String>(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text("选择频道"),
                                              content: SizedBox(
                                                height: 200,
                                                width: MediaQuery.of(context).size.width * 0.75 >= 300 ? 300 : MediaQuery.of(context).size.width * 0.75,
                                                child: CupertinoPicker(
                                                  magnification: 1.22,
                                                  squeeze: 1.2,
                                                  useMagnifier: true,
                                                  itemExtent: _kItemExtent,
                                                  scrollController: FixedExtentScrollController(
                                                    initialItem: _selectedChannel,
                                                  ),
                                                  onSelectedItemChanged: (int selectedItem) {
                                                    _selectedChannel = selectedItem;
                                                  },
                                                  children: List<Widget>.generate(
                                                    channelList!.length,
                                                    (int index) {
                                                      return Center(
                                                        child: Text(
                                                          channelList![index],
                                                          style: Theme.of(context).textTheme.titleMedium,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('取消'),
                                                ),
                                                FilledButton(
                                                  onPressed: () {
                                                    Navigator.pop(context, channelList![_selectedChannel]);
                                                  },
                                                  child: const Text('确定'),
                                                ),
                                              ],
                                            );
                                          },
                                        ).then((value) {
                                          if (value == null) {
                                            _selectedChannel = 0;
                                          }
                                          setState(() {
                                            channel = value;
                                          });
                                        });
                                      },
                                      child: Text(channel ?? "选择频道"),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                child: Text(
                                  "截止时间",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                child: Text(
                                  "您的搭搭请求将会持续刊载至截止时间为止（您也可在“我的”页中提前取消您发布的搭搭请求），截止时间最多可设置为六个月（按180天计算）后。",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        showDatePicker(
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(
                                            const Duration(
                                              days: 180,
                                            ),
                                          ),
                                          context: context,
                                        ).then((value) {
                                          setState(() {
                                            date = value;
                                          });
                                        });
                                      },
                                      child: Text(date == null ? "选择日期" : date.toString().substring(0, 10)),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        showTimePicker(
                                          initialTime: TimeOfDay.now(),
                                          context: context,
                                        ).then((value) {
                                          setState(() {
                                            time = value;
                                          });
                                        });
                                      },
                                      child: Text(time == null ? "选择时间" : "${time!.hour}:${time!.minute} ${time!.period.name.toUpperCase()}"),
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
        ),
        isPosting
            ? FadeTransition(
                opacity: fadeAnimation,
                child: Container(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.35),
                  child: const Center(
                    child: CupertinoActivityIndicator(),
                  ),
                ),
              )
            : Container(),
      ],
    );
  }
}

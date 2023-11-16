import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta_uni_app/mini_apps/chat_room/home_page/chat_room/message_page.dart';
import 'package:meta_uni_app/reusable_components/snack_bar/normal_snack_bar.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/no_permission_snack_bar.dart';
import '../../../mini_app_manager.dart';

class ChatRoomSecurityGatePage extends StatefulWidget {
  final String chatRoomName;
  final String chatRoomDisplayName;

  const ChatRoomSecurityGatePage({super.key, required this.chatRoomName, required this.chatRoomDisplayName});

  @override
  State<ChatRoomSecurityGatePage> createState() => _ChatRoomSecurityGatePageState();
}

class _ChatRoomSecurityGatePageState extends State<ChatRoomSecurityGatePage> {
  List<Padding> chatRoomRulesWidgets = [];

  final double _kItemExtent = 32.0;
  List<String> _firstOfNickname = [];
  List<String> _middleOfNickname = [];
  List<String> _lastOfNickname = [];

  int _selectedFirstOfNickname = 0;
  int _selectedMiddleOfNickname = 0;
  int _selectedLastOfNickname = 0;

  bool dialogFlag = true;

  late Dio dio;
  late String? jwt;
  late int? uuid;

  late Future<dynamic> init;

  _init() async {
    await _initDio();
    final prefs = await SharedPreferences.getInstance();
    jwt = prefs.getString('jwt');
    uuid = prefs.getInt('uuid');

    await getChatRoomRules();
    await getNicknameGroups();
  }

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  getChatRoomRules() async {
    chatRoomRulesWidgets = [];

    try {
      Response response;
      response = await dio.get(
        '/chatRoom/chatRoomRules/${widget.chatRoomName}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> dataList = response.data['data']['dataList'];
          for (var data in dataList) {
            chatRoomRulesWidgets.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                child: Text(
                  data,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }
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

  getNicknameGroups() async {
    _firstOfNickname = [];
    _middleOfNickname = [];
    _lastOfNickname = [];

    try {
      Response response;
      response = await dio.get(
        '/chatRoom/nicknameGroups',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          var dataList = response.data['data']['firstOfNickname'];
          for (var data in dataList) {
            _firstOfNickname.add(data);
          }

          dataList = response.data['data']['middleOfNickname'];
          for (var data in dataList) {
            _middleOfNickname.add(data);
          }

          dataList = response.data['data']['lastOfNickname'];
          for (var data in dataList) {
            _lastOfNickname.add(data);
          }
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

  @override
  void initState() {
    super.initState();

    init = _init();
  }

  File? avatar;

  Future<CroppedFile?> cropAvatar(XFile image) async {
    return await ImageCropper().cropImage(
      compressQuality: 100,
      sourcePath: image.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪头像',
          toolbarColor: Theme.of(context).colorScheme.secondaryContainer,
          toolbarWidgetColor: Theme.of(context).colorScheme.onSecondaryContainer,
          activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
      ],
    );
  }

  uploadAvatar() async {
    try {
      Response response;
      List<String> mimeType = lookupMimeType(avatar!.path)!.split('/');
      var formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          avatar!.path,
          contentType: MediaType(
            mimeType[0],
            mimeType[1],
          ),
        ),
      });
      response = await dio.post(
        '/chatRoom/avatar',
        data: formData,
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          if (mounted) {
            Navigator.pop(context);
            String nickname = "${_firstOfNickname[_selectedFirstOfNickname]}${_middleOfNickname[_selectedMiddleOfNickname]}${_lastOfNickname[_selectedLastOfNickname]}";
            String avatarUrl = response.data['data'];
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomMessagePage(
                  chatRoomDisplayName: widget.chatRoomDisplayName,
                  chatRoomName: widget.chatRoomName,
                  nickname: nickname,
                  avatar: avatarUrl,
                ),
              ),
            );
          }
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            Navigator.pop(context);
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
          //Message:"禁止上传规定格式以外的头像文件"
          if (mounted) {
            Navigator.pop(context);
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        case 3:
          //Message:"发生错误，头像上传失败"
          if (mounted) {
            Navigator.pop(context);
            getNetworkErrorSnackBar(context);
          }
        default:
          if (mounted) {
            Navigator.pop(context);
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        getNetworkErrorSnackBar(context);
      }
    }
  }

  checkExiledStatus() async {
    try {
      Response response;
      response = await dio.get(
        '/chatRoom/checkExiledStatus/${widget.chatRoomName}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          if (response.data['data']) {
            if (mounted) {
              Navigator.pop(context);
              getNormalSnackBar(context, "您当前处于封禁状态");
            }
          } else {
            uploadAvatar();
          }
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            Navigator.pop(context);
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
          //Message:"该聊天室不存在"
          if (mounted) {
            Navigator.pop(context);
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        default:
          if (mounted) {
            Navigator.pop(context);
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        getNetworkErrorSnackBar(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoomDisplayName),
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
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...chatRoomRulesWidgets,
                          Center(
                            child: FilledButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return StatefulBuilder(
                                      builder: (context, setState) {
                                        return dialogFlag
                                            ? AlertDialog(
                                                title: const Text("你的名字是？"),
                                                content: SizedBox(
                                                  height: 250,
                                                  width: MediaQuery.of(context).size.width * 0.75 >= 300 ? 300 : MediaQuery.of(context).size.width * 0.75,
                                                  child: Column(
                                                    children: [
                                                      SizedBox(
                                                        height: 50,
                                                        child: Text(
                                                          "${_firstOfNickname[_selectedFirstOfNickname]}${_middleOfNickname[_selectedMiddleOfNickname]}${_lastOfNickname[_selectedLastOfNickname]}",
                                                          style: Theme.of(context).textTheme.titleLarge,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: 200,
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: CupertinoPicker(
                                                                magnification: 1.22,
                                                                squeeze: 1.2,
                                                                useMagnifier: true,
                                                                looping: true,
                                                                itemExtent: _kItemExtent,
                                                                scrollController: FixedExtentScrollController(
                                                                  initialItem: _selectedFirstOfNickname,
                                                                ),
                                                                onSelectedItemChanged: (int selectedItem) {
                                                                  setState(() {
                                                                    _selectedFirstOfNickname = selectedItem;
                                                                  });
                                                                },
                                                                children: List<Widget>.generate(
                                                                  _firstOfNickname.length,
                                                                  (int index) {
                                                                    return Center(
                                                                      child: Text(
                                                                        _firstOfNickname[index],
                                                                        style: Theme.of(context).textTheme.titleMedium,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: CupertinoPicker(
                                                                magnification: 1.22,
                                                                squeeze: 1.2,
                                                                useMagnifier: true,
                                                                looping: true,
                                                                itemExtent: _kItemExtent,
                                                                scrollController: FixedExtentScrollController(
                                                                  initialItem: _selectedMiddleOfNickname,
                                                                ),
                                                                onSelectedItemChanged: (int selectedItem) {
                                                                  setState(() {
                                                                    _selectedMiddleOfNickname = selectedItem;
                                                                  });
                                                                },
                                                                children: List<Widget>.generate(
                                                                  _middleOfNickname.length,
                                                                  (int index) {
                                                                    return Center(
                                                                      child: Text(
                                                                        _middleOfNickname[index],
                                                                        style: Theme.of(context).textTheme.titleMedium,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: CupertinoPicker(
                                                                magnification: 1.22,
                                                                squeeze: 1.2,
                                                                useMagnifier: true,
                                                                looping: true,
                                                                itemExtent: _kItemExtent,
                                                                scrollController: FixedExtentScrollController(
                                                                  initialItem: _selectedLastOfNickname,
                                                                ),
                                                                onSelectedItemChanged: (int selectedItem) {
                                                                  setState(() {
                                                                    _selectedLastOfNickname = selectedItem;
                                                                  });
                                                                },
                                                                children: List<Widget>.generate(
                                                                  _lastOfNickname.length,
                                                                  (int index) {
                                                                    return Center(
                                                                      child: Text(
                                                                        _lastOfNickname[index],
                                                                        style: Theme.of(context).textTheme.titleMedium,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: const Text('取消'),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                  FilledButton(
                                                    onPressed: (_selectedFirstOfNickname == 0 && _selectedMiddleOfNickname == 0 && _selectedLastOfNickname == 0)
                                                        ? null
                                                        : () {
                                                            setState(() {
                                                              dialogFlag = false;
                                                            });
                                                          },
                                                    child: const Text('下一步'),
                                                  ),
                                                ],
                                              )
                                            : AlertDialog(
                                                title: const Text("你是谁？"),
                                                content: SizedBox(
                                                  height: 250,
                                                  width: MediaQuery.of(context).size.width * 0.75 >= 300 ? 300 : MediaQuery.of(context).size.width * 0.75,
                                                  child: Column(
                                                    children: [
                                                      SizedBox(
                                                        height: 250,
                                                        child: InkWell(
                                                          borderRadius: BorderRadius.circular(16),
                                                          onTap: () {
                                                            showModalBottomSheet(
                                                              context: context,
                                                              showDragHandle: true,
                                                              builder: (context) {
                                                                return SingleChildScrollView(
                                                                  physics: const BouncingScrollPhysics(),
                                                                  child: Column(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: ListTile.divideTiles(
                                                                      context: context,
                                                                      tiles: [
                                                                        SizedBox(
                                                                          height: 60,
                                                                          child: InkWell(
                                                                            onTap: () async {
                                                                              if (await Permission.photos.request().isGranted) {
                                                                                final imagePicker = ImagePicker();
                                                                                final XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
                                                                                if (mounted) {
                                                                                  if (image != null) {
                                                                                    List<String> mimeType = lookupMimeType(image.path)!.split('/');
                                                                                    if (mimeType[1] == "gif") {
                                                                                      avatar = File.fromUri(
                                                                                        Uri.file(image.path),
                                                                                      );
                                                                                      setState(() {});
                                                                                      if (mounted) {
                                                                                        Navigator.pop(context);
                                                                                      }
                                                                                    } else {
                                                                                      CroppedFile? croppedAvatar = await cropAvatar(image);
                                                                                      if (mounted) {
                                                                                        if (croppedAvatar != null) {
                                                                                          avatar = File.fromUri(
                                                                                            Uri.file(croppedAvatar.path),
                                                                                          );
                                                                                          setState(() {});
                                                                                          if (mounted) {
                                                                                            Navigator.pop(context);
                                                                                          }
                                                                                        }
                                                                                      }
                                                                                    }
                                                                                  }
                                                                                }
                                                                              } else {
                                                                                if (mounted) {
                                                                                  Navigator.pop(context);
                                                                                  getPermissionDeniedSnackBar(context, '未获得相册访问权限');
                                                                                }
                                                                              }
                                                                            },
                                                                            child: const Row(
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              children: [
                                                                                Text('从相册选择照片'),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height: 60,
                                                                          child: InkWell(
                                                                            onTap: () async {
                                                                              if (await Permission.camera.request().isGranted) {
                                                                                final imagePicker = ImagePicker();
                                                                                final XFile? image = await imagePicker.pickImage(source: ImageSource.camera);
                                                                                if (mounted) {
                                                                                  if (image != null) {
                                                                                    CroppedFile? croppedAvatar = await cropAvatar(image);
                                                                                    if (mounted) {
                                                                                      if (croppedAvatar != null) {
                                                                                        avatar = File.fromUri(
                                                                                          Uri.file(croppedAvatar.path),
                                                                                        );
                                                                                        setState(() {});
                                                                                        if (mounted) {
                                                                                          Navigator.pop(context);
                                                                                        }
                                                                                      }
                                                                                    }
                                                                                  }
                                                                                }
                                                                              } else {
                                                                                if (mounted) {
                                                                                  Navigator.pop(context);
                                                                                  getPermissionDeniedSnackBar(context, '未获得相机使用权限');
                                                                                }
                                                                              }
                                                                            },
                                                                            child: const Row(
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              children: [
                                                                                Text('拍照'),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height: 60,
                                                                          child: InkWell(
                                                                            onTap: () {
                                                                              Navigator.pop(context);
                                                                            },
                                                                            child: const Row(
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              children: [
                                                                                Text('取消'),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ).toList(),
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          },
                                                          child: AspectRatio(
                                                            aspectRatio: 1.0,
                                                            child: avatar == null
                                                                ? Container(
                                                                    decoration: BoxDecoration(
                                                                      border: Border.all(
                                                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.75),
                                                                        width: 4,
                                                                      ),
                                                                      borderRadius: BorderRadius.circular(16),
                                                                    ),
                                                                    child: Center(
                                                                      child: Text(
                                                                        "上传头像",
                                                                        style: Theme.of(context).textTheme.titleLarge?.apply(
                                                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                                                                            ),
                                                                      ),
                                                                    ),
                                                                  )
                                                                : ClipRRect(
                                                                    borderRadius: BorderRadius.circular(16),
                                                                    child: Image.file(avatar!),
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: const Text('上一步'),
                                                    onPressed: () {
                                                      setState(() {
                                                        dialogFlag = true;
                                                      });
                                                    },
                                                  ),
                                                  FilledButton(
                                                    onPressed: avatar == null
                                                        ? null
                                                        : () {
                                                            checkExiledStatus();
                                                          },
                                                    child: const Text('确定'),
                                                  ),
                                                ],
                                              );
                                      },
                                    );
                                  },
                                ).then((value) {
                                  dialogFlag = true;
                                });
                              },
                              child: const Text("我已阅读并同意"),
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

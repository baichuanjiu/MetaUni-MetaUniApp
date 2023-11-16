import 'package:http_parser/http_parser.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:meta_uni_app/bloc/bloc_manager.dart';
import 'package:meta_uni_app/bloc/chat_target_information/models/chat_target_information_update_data.dart';
import 'package:meta_uni_app/database/models/chat/chat.dart';
import 'package:meta_uni_app/database/models/friend/friends_group.dart';
import 'package:meta_uni_app/database/models/friend/friendship.dart';
import 'package:meta_uni_app/database/models/user/user_sync_table.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sqflite/sqflite.dart';
import '../../../bloc/chat_list_tile/models/chat_list_tile_update_data.dart';
import '../../../bloc/contacts/models/should_update_contacts_view_data.dart';
import '../../../database/database_manager.dart';
import '../../../database/models/user/brief_user_information.dart';
import '../../../models/dio_model.dart';
import '../../../reusable_components/logout/logout.dart';
import '../../../reusable_components/media/models/view_media_metadata.dart';
import '../../../reusable_components/media/view_media_page.dart';
import '../../../reusable_components/route_animation/route_animation.dart';
import '../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../reusable_components/snack_bar/no_permission_snack_bar.dart';
import '../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../chats/chat_list_tile/models/brief_chat_target_information.dart';
import 'models/base_profile.dart';
import 'models/friend_profile.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final DioModel dioModel = DioModel();
  late int queryUUID;
  late Future<dynamic> initUserProfile;
  late dynamic userProfile;
  late bool isLoading = true;
  late bool isMe;
  late bool isFriend;

  _initUserProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/userAPI/profile/$queryUUID',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          switch (response.data['data']['profileType']) {
            case "me":
              isMe = true;
              isFriend = false;
              userProfile = BaseProfile.fromJson(response.data['data']['profile']);
              isLoading = false;
              break;
            case "friend":
              isMe = false;
              isFriend = true;
              userProfile = FriendProfile.fromJson(response.data['data']['profile']);
              isLoading = false;
              break;
            case "stranger":
              isMe = false;
              isFriend = false;
              userProfile = BaseProfile.fromJson(response.data['data']['profile']);
              isLoading = false;
              break;
          }
          Database database = await DatabaseManager().getDatabase;
          BriefUserInformationProvider briefUserInformationProvider = BriefUserInformationProvider(database);
          BriefUserInformation briefUserInformation = BriefUserInformation.fromJson(response.data['data']['profile']);
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
            isLoading = true;
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

    setState(() {});
  }

  refreshUserProfile() async {
    setState(() {
      isLoading = true;
    });
    _initUserProfile();
  }

  @override
  void initState() {
    super.initState();

    initUserProfile = _initUserProfile();
  }

  bool isRouteFromFriendMessagePage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (ModalRoute.of(context)!.settings.name == "/user/profile/routeFromFriendMessagePage") {
      isRouteFromFriendMessagePage = true;
    }
    queryUUID = ModalRoute.of(context)!.settings.arguments as int;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initUserProfile,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return const LoadingPage();
          case ConnectionState.active:
            return const LoadingPage();
          case ConnectionState.waiting:
            return const LoadingPage();
          case ConnectionState.done:
            if (snapshot.hasError) {
              return const LoadingPage();
            }
            return isLoading
                ? const LoadingPage()
                : isMe
                    ? MyProfilePage(userProfile)
                    : isFriend
                        ? FriendProfilePage(userProfile, isRouteFromFriendMessagePage, refreshUserProfile)
                        : StrangerProfilePage(userProfile);
          default:
            return const LoadingPage();
        }
      },
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}

class MyProfilePage extends StatefulWidget {
  final BaseProfile userProfile;

  const MyProfilePage(this.userProfile, {super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  ImagePicker imagePicker = ImagePicker();
  final DioModel dioModel = DioModel();

  late String currentNickname = widget.userProfile.nickname;

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

  uploadAvatar(XFile xFile) async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      List<String> mimeType = lookupMimeType(xFile.path)!.split('/');
      var formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          xFile.path,
          contentType: MediaType(
            mimeType[0],
            mimeType[1],
          ),
        ),
      });
      response = await dioModel.dio.put(
        '/metaUni/userAPI/profile/avatar',
        data: formData,
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          BriefUserInformationProvider briefUserInformationProvider = BriefUserInformationProvider(await DatabaseManager().getDatabase);
          briefUserInformationProvider.update(
            {
              "avatar": response.data['data']['avatar'],
              "updatedTime": DateTime.parse(response.data['data']['updatedTime']).millisecondsSinceEpoch,
            },
            uuid!,
          );
          if (mounted) {
            Navigator.pop(context);
          }
          setState(() {
            widget.userProfile.avatar = response.data['data']['avatar'];
          });
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

  uploadCroppedAvatar(CroppedFile croppedAvatar) async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      List<String> mimeType = lookupMimeType(croppedAvatar.path)!.split('/');
      var formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          croppedAvatar.path,
          contentType: MediaType(
            mimeType[0],
            mimeType[1],
          ),
        ),
      });
      response = await dioModel.dio.put(
        '/metaUni/userAPI/profile/avatar',
        data: formData,
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          BriefUserInformationProvider briefUserInformationProvider = BriefUserInformationProvider(await DatabaseManager().getDatabase);
          briefUserInformationProvider.update(
            {
              "avatar": response.data['data']['avatar'],
              "updatedTime": DateTime.parse(response.data['data']['updatedTime']).millisecondsSinceEpoch,
            },
            uuid!,
          );
          if (mounted) {
            Navigator.pop(context);
          }
          setState(() {
            widget.userProfile.avatar = response.data['data']['avatar'];
          });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("个人信息"),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(15),
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
                                              final XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
                                              if (mounted) {
                                                if (image != null) {
                                                  List<String> mimeType = lookupMimeType(image.path)!.split('/');
                                                  if (mimeType[1] == "gif") {
                                                    await uploadAvatar(image);
                                                  } else {
                                                    CroppedFile? croppedAvatar = await cropAvatar(image);
                                                    if (mounted) {
                                                      if (croppedAvatar != null) {
                                                        await uploadCroppedAvatar(croppedAvatar);
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
                                              final XFile? image = await imagePicker.pickImage(source: ImageSource.camera);
                                              if (mounted) {
                                                if (image != null) {
                                                  CroppedFile? croppedAvatar = await cropAvatar(image);
                                                  if (mounted) {
                                                    if (croppedAvatar != null) {
                                                      await uploadCroppedAvatar(croppedAvatar);
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
                                            Navigator.push(
                                              context,
                                              routeFadeIn(
                                                page: ViewMediaPage(
                                                  dataList: [
                                                    ViewMediaMetadata(
                                                      type: "image",
                                                      heroTag: "avatar",
                                                      imageURL: widget.userProfile.avatar,
                                                    ),
                                                  ],
                                                  initialPage: 0,
                                                  canShare: true,
                                                ),
                                                opaque: false,
                                              ),
                                            );
                                          },
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text('查看大图'),
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
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                          child: Stack(
                            children: [
                              Avatar(widget.userProfile.avatar),
                              Positioned(
                                bottom: -28,
                                right: -28,
                                child: Container(
                                  height: 60,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 1,
                                right: 1,
                                child: Icon(
                                  Icons.camera_outlined,
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<String?>(
                                        builder: (context) => EditNicknamePage(currentNickname: currentNickname),
                                      ),
                                    ).then((value) {
                                      if (value != null) {
                                        setState(() {
                                          currentNickname = value;
                                        });
                                      }
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Text(
                                        currentNickname,
                                        style: Theme.of(context).textTheme.headlineSmall,
                                      ),
                                      Container(
                                        width: 5,
                                      ),
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  child: RoleChips(widget.userProfile.roles),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 10,
                  ),
                  BaseInformationCard(widget.userProfile),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class EditNicknamePage extends StatefulWidget {
  final String currentNickname;

  const EditNicknamePage({super.key, required this.currentNickname});

  @override
  State<EditNicknamePage> createState() => _EditNickNamePageState();
}

class _EditNickNamePageState extends State<EditNicknamePage> {
  final TextEditingController nicknameController = TextEditingController();
  String? _errorText;

  onEditingComplete() async {
    if (nicknameController.text != widget.currentNickname) {
      List<String> check = nicknameController.text.split(
        RegExp(r" +"),
      );
      check.removeWhere((element) => element == "");

      if (check.isEmpty) {
        setState(() {
          _errorText = '昵称不可为空';
        });
      } else {
        final DioModel dioModel = DioModel();
        final prefs = await SharedPreferences.getInstance();

        final String? jwt = prefs.getString('jwt');
        final int? uuid = prefs.getInt('uuid');

        try {
          Response response;
          response = await dioModel.dio.put(
            '/metaUni/userAPI/profile/nickname/${nicknameController.text}',
            options: Options(headers: {
              'JWT': jwt,
              'UUID': uuid,
            }),
          );
          switch (response.data['code']) {
            case 0:
              BriefUserInformationProvider briefUserInformationProvider = BriefUserInformationProvider(await DatabaseManager().getDatabase);
              briefUserInformationProvider.update(
                {
                  "nickname": response.data['data']['nickname'],
                  "updatedTime": DateTime.parse(response.data['data']['updatedTime']).millisecondsSinceEpoch,
                },
                uuid!,
              );
              if (mounted) {
                Navigator.pop(context, response.data['data']['nickname']);
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
            //Message:"昵称不可为空"
            case 3:
              //Message:"昵称超过长度限制"
              if (mounted) {
                getNormalSnackBar(context, response.data['message']);
              }
              setState(() {
                _errorText = response.data['message'];
              });
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
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();

    nicknameController.text = widget.currentNickname;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("修改昵称"),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: TextButton(
              onPressed: onEditingComplete,
              child: const Text("完成"),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: TextField(
          controller: nicknameController,
          decoration: InputDecoration(
            filled: true,
            border: const OutlineInputBorder(borderSide: BorderSide.none),
            errorText: _errorText,
            suffixIcon: IconButton(
              onPressed: () {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                } else {
                  setState(() {});
                }
                nicknameController.clear();
              },
              icon: const Icon(Icons.cancel_outlined),
              tooltip: '清空',
            ),
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          autofocus: true,
          maxLength: 15,
          maxLines: 1,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          onChanged: (value) {
            setState(() {
              _errorText = null;
            });
          },
          onEditingComplete: onEditingComplete,
        ),
      ),
    );
  }
}

class FriendProfilePage extends StatefulWidget {
  final FriendProfile userProfile;
  final bool isRouteFromFriendMessagePage;
  final Function refreshProfilePage;

  const FriendProfilePage(this.userProfile, this.isRouteFromFriendMessagePage, this.refreshProfilePage, {super.key});

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("个人信息"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<bool?>(
                  builder: (context) => UserProfileSettingsPage(
                    uuid: widget.userProfile.uuid,
                    friendshipId: widget.userProfile.friendshipId,
                    nickname: widget.userProfile.nickname,
                  ),
                ),
              ).then((value) {
                if (value == true) {
                  widget.refreshProfilePage();
                }
              });
            },
            icon: const Icon(
              Icons.manage_accounts_outlined,
            ),
            tooltip: '设置',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                routeFadeIn(
                                  page: ViewMediaPage(
                                    dataList: [
                                      ViewMediaMetadata(
                                        type: "image",
                                        heroTag: "avatar",
                                        imageURL: widget.userProfile.avatar,
                                      ),
                                    ],
                                    initialPage: 0,
                                    canShare: true,
                                  ),
                                  opaque: false,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                              child: Avatar(widget.userProfile.avatar),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Text(
                                      widget.userProfile.nickname,
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                      child: RoleChips(widget.userProfile.roles),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 10,
                      ),
                      FriendInformationCard(widget.userProfile),
                      Container(
                        height: 80,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    width: 1,
                  ),
                ),
                color: Theme.of(context).colorScheme.surface,
              ),
              width: MediaQuery.of(context).size.width,
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.call_outlined,
                    ),
                    label: const Text("音视频通话"),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      if (widget.isRouteFromFriendMessagePage) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushNamed(
                          context,
                          '/chats/message/friend',
                          arguments: BriefChatTargetInformation(
                            chatId: null,
                            targetType: "user",
                            id: widget.userProfile.uuid,
                            avatar: widget.userProfile.avatar,
                            name: widget.userProfile.remark != null ? widget.userProfile.remark! : widget.userProfile.nickname,
                            updatedTime: widget.userProfile.updatedTime,
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.sms_outlined,
                    ),
                    label: const Text("发消息"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditRemarkPage extends StatefulWidget {
  final int friendshipId;
  final int uuid;
  final String? currentRemark;
  final String nickname;

  const EditRemarkPage({super.key, required this.friendshipId, required this.uuid, required this.currentRemark, required this.nickname});

  @override
  State<EditRemarkPage> createState() => _EditRemarkPageState();
}

class _EditRemarkPageState extends State<EditRemarkPage> {
  final TextEditingController remarkController = TextEditingController();
  String? _errorText;

  onEditingComplete() async {
    if (remarkController.text != widget.currentRemark) {
      if (remarkController.text.isNotEmpty) {
        List<String> check = remarkController.text.split(
          RegExp(r" +"),
        );
        check.removeWhere((element) => element == "");

        if (check.isEmpty) {
          setState(() {
            _errorText = '备注不可以只含有空格';
          });
          return;
        }
      }

      final DioModel dioModel = DioModel();
      final prefs = await SharedPreferences.getInstance();

      final String? jwt = prefs.getString('jwt');
      final int? uuid = prefs.getInt('uuid');

      try {
        Response response;
        response = await dioModel.dio.put(
          '/metaUni/userAPI/friendship/remark',
          data: {
            "friendshipId": widget.friendshipId,
            "remark": remarkController.text.isEmpty ? null : remarkController.text,
          },
          options: Options(headers: {
            'JWT': jwt,
            'UUID': uuid,
          }),
        );
        switch (response.data['code']) {
          case 0:
            Database database = await DatabaseManager().getDatabase;
            FriendshipProvider friendshipProvider = FriendshipProvider(database);
            friendshipProvider.update({
              "remark": response.data['data']["remark"],
              "updatedTime": DateTime.parse(response.data['data']['updatedTime']).millisecondsSinceEpoch,
            }, response.data['data']["friendshipId"]);

            UserSyncTableProvider userSyncTableProvider = UserSyncTableProvider(database);
            userSyncTableProvider.update({
              'updatedTimeForFriendships': DateTime.parse(response.data['data']['updatedTime']).millisecondsSinceEpoch,
            }, uuid!);
            BlocManager().shouldUpdateContactsViewCubit.shouldUpdate(
                  ShouldUpdateContactsViewData(),
                );

            ChatProvider chatProvider = ChatProvider(database);
            int? chatId = await (chatProvider.getWithUserNotDeleted(widget.uuid));
            if (chatId != null) {
              BlocManager().chatListTileDataCubit.shouldUpdate(
                    ChatListTileUpdateData(chatId: chatId),
                  );
              BlocManager().chatTargetInformationCubit.shouldUpdate(
                    ChatTargetInformationUpdateData(
                      chatId: chatId,
                      name: response.data['data']["remark"] ?? widget.nickname,
                    ),
                  );
            }

            if (mounted) {
              Navigator.pop(context, response.data['data']["remark"] ?? "");
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
          //Message:"该好友关系不存在"
          case 3:
          //Message:"该用户不是您的好友"
          case 4:
          //Message:"备注不可为空"
          case 5:
            //Message:"备注长度超过限制"
            if (mounted) {
              getNormalSnackBar(context, response.data['message']);
            }
            setState(() {
              _errorText = response.data['message'];
            });
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
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();

    remarkController.text = widget.currentRemark ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("修改备注"),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: TextButton(
              onPressed: onEditingComplete,
              child: const Text("完成"),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: TextField(
          controller: remarkController,
          decoration: InputDecoration(
            filled: true,
            border: const OutlineInputBorder(borderSide: BorderSide.none),
            errorText: _errorText,
            suffixIcon: IconButton(
              onPressed: () {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                } else {
                  setState(() {});
                }
                remarkController.clear();
              },
              icon: const Icon(Icons.cancel_outlined),
              tooltip: '清空',
            ),
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          autofocus: true,
          maxLength: 15,
          maxLines: 1,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          onChanged: (value) {
            setState(() {
              _errorText = null;
            });
          },
          onEditingComplete: onEditingComplete,
        ),
      ),
    );
  }
}

class StrangerProfilePage extends StatefulWidget {
  final BaseProfile userProfile;

  const StrangerProfilePage(this.userProfile, {super.key});

  @override
  State<StrangerProfilePage> createState() => _StrangerProfilePageState();
}

class _StrangerProfilePageState extends State<StrangerProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("个人信息"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileSettingsPage(
                    uuid: widget.userProfile.uuid,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.manage_accounts_outlined,
            ),
            tooltip: '设置',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                routeFadeIn(
                                  page: ViewMediaPage(
                                    dataList: [
                                      ViewMediaMetadata(
                                        type: "image",
                                        heroTag: "avatar",
                                        imageURL: widget.userProfile.avatar,
                                      ),
                                    ],
                                    initialPage: 0,
                                    canShare: true,
                                  ),
                                  opaque: false,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                              child: Avatar(widget.userProfile.avatar),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Text(
                                      widget.userProfile.nickname,
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                      child: RoleChips(widget.userProfile.roles),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 10,
                      ),
                      BaseInformationCard(widget.userProfile),
                      Container(
                        height: 80,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    width: 1,
                  ),
                ),
                color: Theme.of(context).colorScheme.surface,
              ),
              width: MediaQuery.of(context).size.width,
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/contacts/add/friend',
                        arguments: BriefUserInformation(
                          uuid: widget.userProfile.uuid,
                          avatar: widget.userProfile.avatar,
                          nickname: widget.userProfile.nickname,
                          updatedTime: widget.userProfile.updatedTime,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.person_add_alt_outlined,
                    ),
                    label: const Text("加好友"),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/chats/message/friend',
                        arguments: BriefChatTargetInformation(
                          chatId: null,
                          targetType: "user",
                          id: widget.userProfile.uuid,
                          avatar: widget.userProfile.avatar,
                          name: widget.userProfile.nickname,
                          updatedTime: widget.userProfile.updatedTime,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.sms_outlined,
                    ),
                    label: const Text("发消息"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserProfileSettingsPage extends StatefulWidget {
  final int uuid;
  final int? friendshipId;
  final String? nickname;

  const UserProfileSettingsPage({super.key, required this.uuid, this.friendshipId, this.nickname});

  @override
  State<UserProfileSettingsPage> createState() => _UserProfileSettingsPageState();
}

class _UserProfileSettingsPageState extends State<UserProfileSettingsPage> {
  late bool isBlocking = false;
  late bool checkBlockStatusFlag = false;

  late Future<dynamic> init;
  final DioModel dioModel = DioModel();
  late final String? jwt;
  late final int? uuid;

  _init() async {
    final prefs = await SharedPreferences.getInstance();

    jwt = prefs.getString('jwt');
    uuid = prefs.getInt('uuid');

    await _checkBlockingStatus();
  }

  _checkBlockingStatus() async {
    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/userAPI/user/block/check/${widget.uuid}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          isBlocking = response.data['data'];
          checkBlockStatusFlag = true;
          setState(() {});
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

  changeBlockingStatus() async {
    try {
      Response response;
      response = await dioModel.dio.put(
        '/metaUni/userAPI/user/block/${widget.uuid}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          isBlocking = response.data['data'];
          setState(() {});
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

  deleteFriendship() async {
    try {
      Response response;
      response = await dioModel.dio.delete(
        '/metaUni/userAPI/friendship/${widget.friendshipId}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          if (mounted) {
            Database database = await DatabaseManager().getDatabase;
            FriendshipProvider friendshipProvider = FriendshipProvider(database);

            Friendship friendship = Friendship.fromJson(response.data["data"]["friendship"]);
            if (await friendshipProvider.get(friendship.id) == null) {
              friendshipProvider.insert(friendship);
            } else {
              friendshipProvider.update(friendship.toUpdateSql(), friendship.id);
            }
            UserSyncTableProvider userSyncTableProvider = UserSyncTableProvider(database);
            userSyncTableProvider.update({
              'updatedTimeForFriendships': friendship.updatedTime.millisecondsSinceEpoch,
            }, uuid!);
            BlocManager().shouldUpdateContactsViewCubit.shouldUpdate(
                  ShouldUpdateContactsViewData(),
                );

            ChatProvider chatProvider = ChatProvider(database);
            int? chatId = await (chatProvider.getWithUserNotDeleted(widget.uuid));
            if (chatId != null) {
              BlocManager().chatListTileDataCubit.shouldUpdate(
                    ChatListTileUpdateData(chatId: chatId),
                  );
              BlocManager().chatTargetInformationCubit.shouldUpdate(
                    ChatTargetInformationUpdateData(
                      chatId: chatId,
                      name: widget.nickname!,
                    ),
                  );
            }

            if (mounted) {
              getNormalSnackBar(context, response.data['message']);
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            }
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
          //Message:"您无法对不是好友的用户进行该操作"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            Navigator.of(context).pop();
            Navigator.of(context).pop(true);
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
        title: const Text("设置"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: const Text("屏蔽此人"),
              trailing: FutureBuilder(
                future: init,
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                      return const CupertinoActivityIndicator();
                    case ConnectionState.active:
                      return const CupertinoActivityIndicator();
                    case ConnectionState.waiting:
                      return const CupertinoActivityIndicator();
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return const CupertinoActivityIndicator();
                      }
                      if (checkBlockStatusFlag) {
                        return Switch(
                          value: isBlocking,
                          onChanged: (value) {
                            changeBlockingStatus();
                          },
                        );
                      } else {
                        return const CupertinoActivityIndicator();
                      }
                    default:
                      return const CupertinoActivityIndicator();
                  }
                },
              ),
            ),
            widget.friendshipId == null
                ? Container()
                : Container(
                    margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text('确定要删除吗？'),
                            content: const SingleChildScrollView(
                              child: ListBody(
                                children: [
                                  Text('删除好友的同时将会自动屏蔽对方，不再接收此人的消息。'),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                child: const Text('取消'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              FilledButton(
                                child: const Text('确定删除'),
                                onPressed: () async {
                                  deleteFriendship();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "删除好友",
                              style: Theme.of(context).textTheme.titleMedium?.apply(color: Theme.of(context).colorScheme.error.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
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
    return Hero(
      tag: 'avatar',
      child: CachedNetworkImage(
          fadeInDuration: const Duration(milliseconds: 800),
          fadeOutDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => SizedBox(
            width: 90,
            height: 90,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: const Center(
                child: CupertinoActivityIndicator(),
              ),
            ),
          ),
          imageUrl: avatar,
          imageBuilder: (context, imageProvider) => SizedBox(
            width: 90,
            height: 90,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image(
                image: imageProvider,
              ),
            ),
          ),
          errorWidget: (context, url, error) => SizedBox(
            width: 90,
            height: 90,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: const Center(
                child: Icon(Icons.error_outline),
              ),
            ),
          )
      ),
    );
  }
}

class RoleChips extends StatelessWidget {
  final List<String> roles;

  const RoleChips(this.roles, {super.key});

  Widget getChip(context, IconData icon, String label) {
    return Chip(
      side: BorderSide.none,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      avatar: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.onSecondaryContainer),
      ),
    );
  }

  List<Widget> getRoleChips(context, List<String> roles) {
    List<Widget> chips = [];
    for (String role in roles) {
      switch (role) {
        case 'administrator':
          chips.add(
            Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 7, 0),
              child: getChip(context, Icons.badge_outlined, '管理员'),
            ),
          );
          break;
        case 'student':
          chips.add(
            Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 7, 0),
              child: getChip(context, Icons.school_outlined, '学生'),
            ),
          );
          break;
        case 'teacher':
          chips.add(
            Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 7, 0),
              child: getChip(context, Icons.auto_stories_outlined, '教师'),
            ),
          );
          break;
        default:
          break;
      }
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: getRoleChips(context, roles),
    );
  }
}

class BaseInformationCard extends StatelessWidget {
  final BaseProfile userProfile;

  const BaseInformationCard(this.userProfile, {super.key});

  List<Widget> getListTiles() {
    List<Widget> listTiles = [];
    listTiles.add(
      ListTile(
        title: const Text('账号'),
        subtitle: Text(userProfile.account),
      ),
    );
    listTiles.add(
      ListTile(
        title: const Text('UUID'),
        subtitle: Text(userProfile.uuid.toString()),
      ),
    );
    listTiles.add(
      ListTile(
        title: const Text('性别'),
        subtitle: Text(userProfile.gender),
      ),
    );
    listTiles.add(
      ListTile(
        title: const Text('校区'),
        subtitle: Text(userProfile.campus),
      ),
    );
    listTiles.add(
      ListTile(
        title: const Text('院系'),
        subtitle: Text(userProfile.department),
      ),
    );
    if (userProfile.major != null) {
      listTiles.add(
        ListTile(
          title: const Text('专业'),
          subtitle: Text(userProfile.major!),
        ),
      );
    }
    if (userProfile.grade != null) {
      listTiles.add(
        ListTile(
          title: const Text('年级'),
          subtitle: Text(userProfile.grade!),
        ),
      );
    }
    return listTiles;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: ListTile.divideTiles(
          context: context,
          tiles: getListTiles(),
        ).toList(),
      ),
    );
  }
}

class FriendInformationCard extends StatefulWidget {
  final FriendProfile userProfile;

  const FriendInformationCard(this.userProfile, {super.key});

  @override
  State<FriendInformationCard> createState() => _FriendInformationCardState();
}

class _FriendInformationCardState extends State<FriendInformationCard> {
  late String friendsGroupName = "";
  late String? currentRemark = widget.userProfile.remark;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    Database database = await DatabaseManager().getDatabase;
    FriendsGroupProvider friendsGroupProvider = FriendsGroupProvider(database);

    friendsGroupName = (await friendsGroupProvider.getName(widget.userProfile.friendsGroupId))!;
    setState(() {});
  }

  List<Widget> getListTiles() {
    List<Widget> listTiles = [];
    listTiles.add(
      ListTile(
        title: const Text('账号'),
        subtitle: Text(widget.userProfile.account),
      ),
    );
    listTiles.add(
      ListTile(
        title: const Text('UUID'),
        subtitle: Text(widget.userProfile.uuid.toString()),
      ),
    );
    listTiles.add(
      ListTile(
        title: const Text('备注'),
        subtitle: Text(currentRemark ?? "无"),
        trailing: const Icon(
          Icons.chevron_right_outlined,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<String?>(
              builder: (context) => EditRemarkPage(
                friendshipId: widget.userProfile.friendshipId,
                uuid: widget.userProfile.uuid,
                currentRemark: currentRemark,
                nickname: widget.userProfile.nickname,
              ),
            ),
          ).then((value) {
            if (value != null) {
              setState(() {
                currentRemark = value.isEmpty ? null : value;
              });
            }
          });
        },
      ),
    );
    listTiles.add(
      ListTile(
        title: const Text('好友分组'),
        subtitle: Text(friendsGroupName),
        trailing: const Icon(
          Icons.chevron_right_outlined,
        ),
        onTap: () {},
      ),
    );
    listTiles.add(
      ListTile(
        title: const Text('性别'),
        subtitle: Text(widget.userProfile.gender),
      ),
    );
    listTiles.add(
      ListTile(
        title: const Text('校区'),
        subtitle: Text(widget.userProfile.campus),
      ),
    );
    listTiles.add(
      ListTile(
        title: const Text('院系'),
        subtitle: Text(widget.userProfile.department),
      ),
    );
    if (widget.userProfile.major != null) {
      listTiles.add(
        ListTile(
          title: const Text('专业'),
          subtitle: Text(widget.userProfile.major!),
        ),
      );
    }
    if (widget.userProfile.grade != null) {
      listTiles.add(
        ListTile(
          title: const Text('年级'),
          subtitle: Text(widget.userProfile.grade!),
        ),
      );
    }
    return listTiles;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: ListTile.divideTiles(
          context: context,
          tiles: getListTiles(),
        ).toList(),
      ),
    );
  }
}

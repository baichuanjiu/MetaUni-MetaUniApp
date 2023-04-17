import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../database/database_manager.dart';
import '../../../../database/models/user/brief_user_information.dart';
import '../../../../models/dio_model.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/no_permission_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import 'models/user_profile.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final DioModel dioModel = DioModel();
  late int queryUUID;
  late Future<dynamic> initUserProfile;
  late UserProfile userProfile;
  late bool isLoading = true;
  late bool isReadonly;

  _initUserProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dioModel.dio.get(
        '/user/profile/$queryUUID',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
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
          if (queryUUID != uuid) {
            isReadonly = true;
          } else {
            isReadonly = false;
          }
          userProfile = UserProfile.fromJson(response.data['data']);
          isLoading = false;
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

    initUserProfile = _initUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    queryUUID = ModalRoute.of(context)!.settings.arguments as int;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人信息'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
        ),
      ),
      body: FutureBuilder(
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
                    : isReadonly
                        ? ReadonlyPage(userProfile)
                        : EditablePage(userProfile);
              default:
                return const LoadingPage();
            }
          }),
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}

class ReadonlyPage extends StatelessWidget {
  final UserProfile userProfile;

  const ReadonlyPage(this.userProfile, {super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                  Navigator.pushNamed(
                    context,
                    '/view/image',
                    arguments: {
                      "heroTag": "avatar",
                      "image": userProfile.avatar,
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  child: Avatar(userProfile.avatar),
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
                          userProfile.nickname,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          child: RoleChips(userProfile.roles),
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
          InformationCard(userProfile),
        ],
      ),
    );
  }
}

class EditablePage extends StatefulWidget {
  final UserProfile userProfile;

  const EditablePage(this.userProfile, {super.key});

  @override
  State<EditablePage> createState() => _EditablePageState();
}

class _EditablePageState extends State<EditablePage> {
  ImagePicker imagePicker = ImagePicker();
  final DioModel dioModel = DioModel();

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
            lockAspectRatio: true),
      ],
    );
  }

  uploadAvatar(CroppedFile croppedAvatar) async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      var formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(croppedAvatar.path),
      });
      response = await dioModel.dio.put(
        '/user/profile/avatar',
        data: formData,
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            Navigator.pop(context);
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
          //Message:"发生错误，头像上传失败"
          if (mounted) {
            Navigator.pop(context);
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        default:
          if (mounted) {
            BriefUserInformationProvider briefUserInformationProvider = BriefUserInformationProvider(await DatabaseManager().getDatabase);
            briefUserInformationProvider.update(
              {
                "avatar": response.data['data'],
              },
              uuid!,
            );
            if (mounted) {
              Navigator.pop(context);
            }
            setState(() {
              widget.userProfile.avatar = response.data['data'];
            });
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
    return SingleChildScrollView(
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
                    builder: (context) {
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 288),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 4,
                                  width: 32,
                                  margin: const EdgeInsets.fromLTRB(0, 22, 0, 22),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: SingleChildScrollView(
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
                                                  CroppedFile? croppedAvatar = await cropAvatar(image);
                                                  if (mounted) {
                                                    if (croppedAvatar != null) {
                                                      await uploadAvatar(croppedAvatar);
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
                                                      await uploadAvatar(croppedAvatar);
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
                                            Navigator.pushNamed(
                                              context,
                                              '/view/image',
                                              arguments: {
                                                "heroTag": "avatar",
                                                "image": widget.userProfile.avatar,
                                              },
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
                              ),
                            ),
                          ],
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
                            Navigator.pushNamed(context, '/edit/nickname');
                          },
                          child: Row(
                            children: [
                              Text(
                                widget.userProfile.nickname,
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
          InformationCard(widget.userProfile),
        ],
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
        placeholder: (context, url) => const CupertinoActivityIndicator(),
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
        errorWidget: (context, url, error) => const Icon(Icons.error_outline),
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

class InformationCard extends StatelessWidget {
  final UserProfile userProfile;

  const InformationCard(this.userProfile, {super.key});

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
        title: const Text('姓名'),
        subtitle: Text('${userProfile.surname}  ${userProfile.name}'),
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

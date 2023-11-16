import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../reusable_components/logout/logout.dart';
import '../../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../../reusable_components/snack_bar/no_permission_snack_bar.dart';
import '../../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../../mini_app_manager.dart';
import '../card/user_card.dart';
import '../models/user_card_data.dart';

class UserCardEditPage extends StatefulWidget {
  final UserCardData data;

  const UserCardEditPage({super.key, required this.data});

  @override
  State<UserCardEditPage> createState() => _UserCardEditPageState();
}

class _UserCardEditPageState extends State<UserCardEditPage> {
  late UserCardData userCardData = UserCardData(widget.data.user, widget.data.summary, widget.data.backgroundImage);

  late String? summary = widget.data.summary;
  File? backgroundImage;

  _editUserCard() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    final uuid = prefs.getInt('uuid');

    Map<String, dynamic> formDataMap = {
      'summary': summary,
    };

    if (backgroundImage != null) {
      List<String> mimeType = lookupMimeType(backgroundImage!.path)!.split('/');
      if (mimeType[0] == 'image') {
        var decodedImage = await decodeImageFromList(
          backgroundImage!.readAsBytesSync(),
        );
        final newEntries = {
          'backgroundImage.File': await MultipartFile.fromFile(
            backgroundImage!.path,
            contentType: MediaType(
              mimeType[0],
              mimeType[1],
            ),
          ),
          'backgroundImage.AspectRatio': decodedImage.width / decodedImage.height,
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
      response = await dio.put(
        '/seekPartner/leafletAPI/user/me/userCard',
        data: formData,
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            Navigator.pop(context, true);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("编辑名片"),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: TextButton(
              onPressed: () {
                if (backgroundImage == null && summary == widget.data.summary) {
                  Navigator.pop(context);
                } else {
                  _editUserCard();
                }
              },
              child: const Text("确定"),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 0, 0, 10),
              child: Text(
                '预览',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            UserCard(
              data: userCardData,
              backgroundImagePreview: backgroundImage,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton.tonal(
                    onPressed: () {
                      final TextEditingController summaryController = TextEditingController();
                      final FocusNode summaryFocusNode = FocusNode();

                      summaryController.text = summary ?? "";

                      showModalBottomSheet<String?>(
                        context: context,
                        showDragHandle: true,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return Container(
                                margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "编辑个性签名",
                                              style: Theme.of(context).textTheme.titleLarge,
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextField(
                                        controller: summaryController,
                                        focusNode: summaryFocusNode,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          filled: true,
                                          labelText: "个性签名",
                                        ),
                                        maxLength: 50,
                                        maxLines: 1,
                                        textInputAction: TextInputAction.done,
                                        onTapOutside: (details) {
                                          summaryFocusNode.unfocus();
                                        },
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          FilledButton(
                                            onPressed: () {
                                              Navigator.pop(
                                                context,
                                                summaryController.text.isEmpty ? null : summaryController.text,
                                              );
                                            },
                                            child: const Text("确定"),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ).then((value) {
                        setState(() {
                          summary = value;
                          userCardData.summary = summary;
                        });
                      });
                    },
                    child: const Text("个性签名"),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (await Permission.photos.request().isGranted) {
                        final ImagePicker imagePicker = ImagePicker();
                        final XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
                        if (mounted) {
                          if (image != null) {
                            setState(() {
                              backgroundImage = File(image.path);
                            });
                          }
                        }
                      } else {
                        if (mounted) {
                          getPermissionDeniedSnackBar(context, '未获得相册访问权限');
                        }
                      }
                    },
                    child: const Text("背景图片"),
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

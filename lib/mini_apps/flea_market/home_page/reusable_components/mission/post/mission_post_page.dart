import 'package:flutter/cupertino.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta_uni_app/mini_apps/flea_market/home_page/models/price/price_data.dart';
import 'package:meta_uni_app/reusable_components/gallery/function/pick_multiple_medias_modal.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';
import '../../../../../../reusable_components/logout/logout.dart';
import '../../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../../reusable_components/snack_bar/no_permission_snack_bar.dart';
import '../../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../../mini_app_manager.dart';
import '../../channel/models/channel_data.dart';
import '../../channel/select/channel_select_page.dart';
import '../details/mission_details_page.dart';
import 'label_preview.dart';
import 'media_preview.dart';

class SelectedAsset {
  final DateTime timestamp;
  final AssetEntity asset;

  SelectedAsset({required this.timestamp, required this.asset});
}

class CameraMedia {
  final DateTime timestamp;
  final bool isVideo;
  final XFile media;

  CameraMedia({required this.timestamp, this.isVideo = false, required this.media});
}

class MissionPostPage extends StatefulWidget {
  const MissionPostPage({
    super.key,
  });

  @override
  State<MissionPostPage> createState() => _MissionPostPageState();
}

class _MissionPostPageState extends State<MissionPostPage> with TickerProviderStateMixin {
  String postMode = "sell";

  final formKey = GlobalKey<FormState>();

  String title = '';
  final TextEditingController titleController = TextEditingController();
  final FocusNode titleFocusNode = FocusNode();

  String description = '';
  final TextEditingController descriptionController = TextEditingController();
  final FocusNode descriptionFocusNode = FocusNode();

  final ImagePicker mediaPicker = ImagePicker();
  List<SelectedAsset> selectedAssets = [];
  List<CameraMedia> cameraMedias = [];
  List<File> medias = [];
  List<MediaPreview> mediaPreviewList = [];

  updateMediaPreviewList() async {
    medias.clear();
    mediaPreviewList.clear();
    int minLength = selectedAssets.length <= cameraMedias.length ? selectedAssets.length : cameraMedias.length;
    int assetsIndex = 0;
    int cameraIndex = 0;
    if (minLength != 0) {
      for (;;) {
        if (selectedAssets[assetsIndex].timestamp.isBefore(cameraMedias[cameraIndex].timestamp)) {
          medias.add((await selectedAssets[assetsIndex].asset.file)!);
          SelectedAsset current = selectedAssets[assetsIndex];
          mediaPreviewList.add(
            MediaPreview(
              file: (await selectedAssets[assetsIndex].asset.file)!,
              isVideo: selectedAssets[assetsIndex].asset.type == AssetType.video,
              remove: () {
                selectedAssets.remove(current);
                updateMediaPreviewList();
              },
            ),
          );

          assetsIndex++;
          if (assetsIndex == selectedAssets.length) {
            break;
          }
        } else {
          medias.add(
            File.fromUri(
              Uri.file(cameraMedias[cameraIndex].media.path),
            ),
          );
          CameraMedia current = cameraMedias[cameraIndex];
          mediaPreviewList.add(
            MediaPreview(
              file: File.fromUri(
                Uri.file(cameraMedias[cameraIndex].media.path),
              ),
              isVideo: cameraMedias[cameraIndex].isVideo,
              remove: () {
                cameraMedias.remove(current);
                updateMediaPreviewList();
              },
            ),
          );

          cameraIndex++;
          if (cameraIndex == cameraMedias.length) {
            break;
          }
        }
      }
    }

    for (; assetsIndex < selectedAssets.length; assetsIndex++) {
      medias.add((await selectedAssets[assetsIndex].asset.file)!);
      SelectedAsset current = selectedAssets[assetsIndex];
      mediaPreviewList.add(
        MediaPreview(
          file: (await selectedAssets[assetsIndex].asset.file)!,
          isVideo: selectedAssets[assetsIndex].asset.type == AssetType.video,
          remove: () {
            selectedAssets.remove(current);
            updateMediaPreviewList();
          },
        ),
      );
    }
    for (; cameraIndex < cameraMedias.length; cameraIndex++) {
      medias.add(
        File.fromUri(
          Uri.file(cameraMedias[cameraIndex].media.path),
        ),
      );
      CameraMedia current = cameraMedias[cameraIndex];
      mediaPreviewList.add(
        MediaPreview(
          file: File.fromUri(
            Uri.file(cameraMedias[cameraIndex].media.path),
          ),
          isVideo: cameraMedias[cameraIndex].isVideo,
          remove: () {
            cameraMedias.remove(current);
            updateMediaPreviewList();
          },
        ),
      );
    }

    setState(() {});
  }

  Map<String, String> labels = {};
  List<LabelPreview> labelPreviewList = [];

  updateLabelPreviewList() {
    labelPreviewList.clear();
    labels.forEach(
      (key, value) {
        labelPreviewList.add(
          LabelPreview(
            label: MapEntry(key, value),
            onRemove: () {
              labels.remove(key);
              updateLabelPreviewList();
            },
          ),
        );
      },
    );
    setState(() {});
  }

  PriceData priceData = PriceData(type: "pending");
  Widget pricePreview = Container();

  String? campus;

  ChannelData? channelData;

  bool isPosting = false;
  late AnimationController fadeAnimationController;
  late Animation<double> fadeAnimation;
  int fadeMilliseconds = 750;

  _postMission() async {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    final uuid = prefs.getInt('uuid');

    setState(() {
      isPosting = true;
      fadeAnimationController.forward();
    });

    Map<String, dynamic> formDataMap = {
      'type': postMode,
      'title': title,
      'description': description,
      'labels': labels,
      'campus': campus,
      'channelData.MainChannel': channelData!.mainChannel,
      'channelData.SubChannel': channelData!.subChannel,
    };

    // pending（待定） accurate（准确价格） range（价格范围）
    if (priceData.type == "accurate") {
      final newEntries = {
        'priceData.Type': priceData.type,
        'priceData.Price': priceData.price,
      };
      formDataMap.addEntries(newEntries.entries);
    } else if (priceData.type == "range") {
      final newEntries = {
        'priceData.Type': priceData.type,
        'priceData.PriceRange.Start': priceData.priceRange!.start,
        'priceData.PriceRange.End': priceData.priceRange!.end,
      };
      formDataMap.addEntries(newEntries.entries);
    } else {
      final newEntries = {'priceData.Type': priceData.type};
      formDataMap.addEntries(newEntries.entries);
    }

    for (int i = 0; i < medias.length; i++) {
      List<String> mimeType = lookupMimeType(medias[i].path)!.split('/');
      if (mimeType[0] == 'image') {
        var decodedImage = await decodeImageFromList(
          medias[i].readAsBytesSync(),
        );
        final newEntries = {
          'medias[$i].File': await MultipartFile.fromFile(
            medias[i].path,
            contentType: MediaType(
              mimeType[0],
              mimeType[1],
            ),
          ),
          'medias[$i].AspectRatio': decodedImage.width / decodedImage.height,
        };
        formDataMap.addEntries(newEntries.entries);
      } else if (mimeType[0] == 'video') {
        File thumbnailFile = await VideoCompress.getFileThumbnail(
          medias[i].path,
        );
        MediaInfo mediaInfo = await VideoCompress.getMediaInfo(medias[i].path);
        final newEntries = {
          'medias[$i].File': await MultipartFile.fromFile(
            medias[i].path,
            contentType: MediaType(
              mimeType[0],
              mimeType[1],
            ),
          ),
          'medias[$i].AspectRatio': mediaInfo.height! / mediaInfo.width!,
          'medias[$i].PreviewImage': await MultipartFile.fromFile(
            thumbnailFile.path,
            contentType: MediaType(
              'image',
              'jpeg',
            ),
          ),
          'medias[$i].TimeTotal': mediaInfo.duration!.toInt(),
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
        '/fleaMarket/marketAPI/mission',
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
                ModalRoute.withName('/miniApps/fleaMarket'),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return MissionDetailsPage(id: response.data['data']['id']);
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
        //Message:"发布失败，发布类型错误"
        case 3:
        //Message:"发布失败，标题或描述不能为空"
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
    switch (priceData.type) {
      case "accurate":
        pricePreview = Text(
          "￥${priceData.price!.toStringAsFixed(2)}",
          style: Theme.of(context).textTheme.labelLarge?.apply(
                color: Colors.orange,
              ),
        );
        break;
      case "range":
        pricePreview = Text(
          "￥${priceData.priceRange!.start.toStringAsFixed(2)} ~ ${priceData.priceRange!.end.toStringAsFixed(2)}",
          style: Theme.of(context).textTheme.labelLarge?.apply(
                color: Colors.orange,
              ),
        );
        break;
      default:
        pricePreview = Text(
          "￥待定",
          style: Theme.of(context).textTheme.labelLarge?.apply(
                color: Colors.orange,
              ),
        );
        break;
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: "sell",
                  label: Text('出售'),
                  icon: Icon(Icons.shopping_basket_outlined),
                ),
                ButtonSegment<String>(
                  value: "purchase",
                  label: Text('求购'),
                  icon: Icon(Icons.currency_yen_outlined),
                ),
              ],
              selected: <String>{postMode},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  postMode = newSelection.first;
                });
              },
              showSelectedIcon: false,
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity(horizontal: -1, vertical: -1),
              ),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: (isStringEmpty(titleController.text) || isStringEmpty(descriptionController.text) || channelData == null)
                    ? null
                    : () {
                        if (formKey.currentState!.validate() && channelData != null) {
                          _postMission();
                        }
                      },
                child: const Text("发布"),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                              child: TextFormField(
                                controller: titleController,
                                focusNode: titleFocusNode,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  labelText: "标题",
                                ),
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLength: 30,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (value) {
                                  if (isStringEmpty(value)) {
                                    return ' 标题 不能为空';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    title = value;
                                  });
                                },
                                onTapOutside: (details) {
                                  titleFocusNode.unfocus();
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                              child: TextFormField(
                                controller: descriptionController,
                                focusNode: descriptionFocusNode,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  filled: true,
                                  hintText: "描述",
                                ),
                                minLines: 3,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                maxLength: 1000,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (value) {
                                  if (isStringEmpty(value)) {
                                    return ' 描述 不能为空';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    description = value;
                                  });
                                },
                                onTapOutside: (details) {
                                  descriptionFocusNode.unfocus();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      medias.isEmpty
                          ? Container()
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                              child: Text(
                                "媒体文件",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.longestSide * 0.15,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  child: Row(
                                    children: [
                                      ...mediaPreviewList,
                                      InkWell(
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
                                                            Navigator.pop(context);
                                                            if (medias.length < 9) {
                                                              if (await Permission.camera.request().isGranted) {
                                                                if (mounted) {
                                                                  XFile? image = await mediaPicker.pickImage(source: ImageSource.camera);
                                                                  if (image == null) {
                                                                    if (Platform.isAndroid) {
                                                                      LostDataResponse response = await mediaPicker.retrieveLostData();
                                                                      if (!response.isEmpty) {
                                                                        image = response.file;
                                                                      }
                                                                    }
                                                                  }
                                                                  if (image != null) {
                                                                    cameraMedias.add(
                                                                      CameraMedia(timestamp: DateTime.now(), media: image),
                                                                    );
                                                                    updateMediaPreviewList();
                                                                  }
                                                                }
                                                              } else {
                                                                if (mounted) {
                                                                  getPermissionDeniedSnackBar(context, '未获得相机使用权限');
                                                                }
                                                              }
                                                            } else {
                                                              getNormalSnackBar(context, "最多仅可上传 9 项媒体文件");
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
                                                          onTap: () async {
                                                            Navigator.pop(context);
                                                            if (medias.length < 9) {
                                                              if (await Permission.camera.request().isGranted) {
                                                                if (mounted) {
                                                                  XFile? video = await mediaPicker.pickVideo(source: ImageSource.camera);
                                                                  if (video == null) {
                                                                    if (Platform.isAndroid) {
                                                                      LostDataResponse response = await mediaPicker.retrieveLostData();
                                                                      if (!response.isEmpty) {
                                                                        video = response.file;
                                                                      }
                                                                    }
                                                                  }
                                                                  if (video != null) {
                                                                    cameraMedias.add(
                                                                      CameraMedia(timestamp: DateTime.now(), isVideo: true, media: video),
                                                                    );
                                                                    updateMediaPreviewList();
                                                                  }
                                                                }
                                                              } else {
                                                                if (mounted) {
                                                                  getPermissionDeniedSnackBar(context, '未获得相机使用权限');
                                                                }
                                                              }
                                                            } else {
                                                              getNormalSnackBar(context, "最多仅可上传 9 项媒体文件");
                                                            }
                                                          },
                                                          child: const Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text('录像'),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: 60,
                                                        child: InkWell(
                                                          onTap: () async {
                                                            Navigator.pop(context);
                                                            if (await Permission.photos.request().isGranted) {
                                                              if (mounted) {
                                                                List<AssetEntity> assets = selectedAssets.map((e) => e.asset).toList();

                                                                assets = await pickMultipleMediasModal(context: context, selectedAssets: assets, maxCount: 9 - cameraMedias.length);

                                                                int minLength = assets.length <= selectedAssets.length ? assets.length : selectedAssets.length;

                                                                int index = 0;
                                                                for (; index < minLength; index++) {
                                                                  if (selectedAssets[index].asset.id != assets[index].id) {
                                                                    break;
                                                                  }
                                                                }

                                                                selectedAssets = selectedAssets.sublist(0, index);

                                                                for (; index < assets.length; index++) {
                                                                  selectedAssets.add(
                                                                    SelectedAsset(timestamp: DateTime.now(), asset: assets[index]),
                                                                  );
                                                                }
                                                                updateMediaPreviewList();
                                                              }
                                                            } else {
                                                              if (mounted) {
                                                                getPermissionDeniedSnackBar(context, '未获得相册访问权限');
                                                              }
                                                            }
                                                          },
                                                          child: const Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text('相册'),
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
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          height: MediaQuery.of(context).size.longestSide * 0.15,
                                          width: MediaQuery.of(context).size.longestSide * 0.15,
                                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_outlined,
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                                                ),
                                                Text(
                                                  "添加图片或视频",
                                                  style: Theme.of(context).textTheme.bodyMedium?.apply(
                                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                                                      ),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 10,
                      ),
                      ListTile(
                        onTap: () {
                          final formKey = GlobalKey<FormState>();
                          final TextEditingController keyController = TextEditingController();
                          final FocusNode keyFocusNode = FocusNode();
                          final TextEditingController valueController = TextEditingController();
                          final FocusNode valueFocusNode = FocusNode();

                          showModalBottomSheet<MapEntry<String, String>>(
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
                                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "添加标签",
                                                  style: Theme.of(context).textTheme.titleLarge,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(0, 5, 0, 10),
                                            child: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: "添加的标签将以 ",
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                  WidgetSpan(
                                                    child: Column(
                                                      children: [
                                                        Text(
                                                          "关键词",
                                                          style: Theme.of(context).textTheme.bodyMedium?.apply(color: Theme.of(context).colorScheme.outline),
                                                        ),
                                                        Text(
                                                          "内容",
                                                          style: Theme.of(context).textTheme.bodyMedium,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: " 的形式在 详情页 展示，清晰简洁的标签有助于其他用户快速提取要点。",
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Form(
                                            key: formKey,
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                                                  child: TextFormField(
                                                    controller: keyController,
                                                    focusNode: keyFocusNode,
                                                    autofocus: true,
                                                    decoration: const InputDecoration(
                                                      border: OutlineInputBorder(),
                                                      filled: true,
                                                      labelText: "关键词",
                                                    ),
                                                    maxLength: 25,
                                                    maxLines: 1,
                                                    textInputAction: TextInputAction.next,
                                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                                    validator: (value) {
                                                      if (isStringEmpty(value)) {
                                                        return ' 关键词 不能为空';
                                                      }
                                                      return null;
                                                    },
                                                    onTapOutside: (details) {
                                                      keyFocusNode.unfocus();
                                                    },
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 10),
                                                  child: TextFormField(
                                                    controller: valueController,
                                                    focusNode: valueFocusNode,
                                                    decoration: const InputDecoration(
                                                      border: OutlineInputBorder(),
                                                      filled: true,
                                                      labelText: "内容",
                                                    ),
                                                    maxLength: 25,
                                                    maxLines: 1,
                                                    textInputAction: TextInputAction.done,
                                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                                    validator: (value) {
                                                      if (isStringEmpty(value)) {
                                                        return ' 内容 不能为空';
                                                      }
                                                      return null;
                                                    },
                                                    onTapOutside: (details) {
                                                      valueFocusNode.unfocus();
                                                    },
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    FilledButton(
                                                      onPressed: () {
                                                        if (formKey.currentState!.validate()) {
                                                          Navigator.pop(
                                                            context,
                                                            MapEntry(keyController.text, valueController.text),
                                                          );
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
                          ).then((value) {
                            if (value != null) {
                              labels.addEntries([value]);
                              updateLabelPreviewList();
                            }
                          });
                        },
                        title: const Text("标签"),
                        trailing: const Text("添加"),
                      ),
                      ...labelPreviewList,
                      Container(
                        height: 10,
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                          child: Column(
                            children: [
                              ListTile(
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
                                                    Navigator.pop(context);
                                                    final TextEditingController priceController = TextEditingController(
                                                      text: priceData.price == null ? "0.00" : priceData.price!.toStringAsFixed(2),
                                                    );
                                                    final FocusNode priceFocusNode = FocusNode();

                                                    showModalBottomSheet<PriceData>(
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
                                                                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                                                                      child: Row(
                                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                                        children: [
                                                                          Text(
                                                                            "精确价格",
                                                                            style: Theme.of(context).textTheme.titleLarge,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                                                                      child: TextField(
                                                                        controller: priceController,
                                                                        focusNode: priceFocusNode,
                                                                        autofocus: true,
                                                                        decoration: const InputDecoration(
                                                                          border: OutlineInputBorder(),
                                                                          filled: true,
                                                                          labelText: "精确价格",
                                                                        ),
                                                                        inputFormatters: [
                                                                          //金额正则
                                                                          FilteringTextInputFormatter.allow(
                                                                            RegExp(r"^[0-9]+[.]?[0-9]{0,2}"),
                                                                          ),
                                                                        ],
                                                                        keyboardType: TextInputType.number,
                                                                        textInputAction: TextInputAction.done,
                                                                        onTapOutside: (details) {
                                                                          priceFocusNode.unfocus();
                                                                        },
                                                                      ),
                                                                    ),
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                      children: [
                                                                        FilledButton(
                                                                          onPressed: () {
                                                                            Navigator.pop(
                                                                              context,
                                                                              PriceData.fromJson(
                                                                                {
                                                                                  'type': 'accurate',
                                                                                  'price': priceController.text.isEmpty ? "0.00" : priceController.text,
                                                                                },
                                                                              ),
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
                                                      if (value != null) {
                                                        setState(() {
                                                          priceData = value;
                                                        });
                                                      }
                                                    });
                                                  },
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text('精确'),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 60,
                                                child: InkWell(
                                                  onTap: () async {
                                                    Navigator.pop(context);
                                                    final TextEditingController rangeStartController = TextEditingController(
                                                      text: priceData.priceRange == null ? "0.00" : priceData.priceRange!.start.toStringAsFixed(2),
                                                    );
                                                    final FocusNode rangeStartFocusNode = FocusNode();
                                                    final TextEditingController rangeEndController = TextEditingController(
                                                      text: priceData.priceRange == null ? "0.00" : priceData.priceRange!.end.toStringAsFixed(2),
                                                    );
                                                    final FocusNode rangeEndFocusNode = FocusNode();

                                                    showModalBottomSheet<PriceData>(
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
                                                                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                                                                      child: Row(
                                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                                        children: [
                                                                          Text(
                                                                            "价格范围",
                                                                            style: Theme.of(context).textTheme.titleLarge,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                                                                      child: TextField(
                                                                        controller: rangeStartController,
                                                                        focusNode: rangeStartFocusNode,
                                                                        autofocus: true,
                                                                        decoration: const InputDecoration(
                                                                          border: OutlineInputBorder(),
                                                                          filled: true,
                                                                          labelText: "起始值",
                                                                        ),
                                                                        inputFormatters: [
                                                                          //金额正则
                                                                          FilteringTextInputFormatter.allow(
                                                                            RegExp(r"^[0-9]+[.]?[0-9]{0,2}"),
                                                                          ),
                                                                        ],
                                                                        keyboardType: TextInputType.number,
                                                                        textInputAction: TextInputAction.next,
                                                                        onTapOutside: (details) {
                                                                          rangeStartFocusNode.unfocus();
                                                                        },
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                                                                      child: TextField(
                                                                        controller: rangeEndController,
                                                                        focusNode: rangeEndFocusNode,
                                                                        autofocus: false,
                                                                        decoration: const InputDecoration(
                                                                          border: OutlineInputBorder(),
                                                                          filled: true,
                                                                          labelText: "结束值",
                                                                        ),
                                                                        inputFormatters: [
                                                                          //金额正则
                                                                          FilteringTextInputFormatter.allow(
                                                                            RegExp(r"^[0-9]+[.]?[0-9]{0,2}"),
                                                                          ),
                                                                        ],
                                                                        keyboardType: TextInputType.number,
                                                                        textInputAction: TextInputAction.done,
                                                                        onTapOutside: (details) {
                                                                          rangeEndFocusNode.unfocus();
                                                                        },
                                                                      ),
                                                                    ),
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                      children: [
                                                                        FilledButton(
                                                                          onPressed: () {
                                                                            Navigator.pop(
                                                                              context,
                                                                              PriceData.fromJson(
                                                                                {
                                                                                  'type': 'range',
                                                                                  'priceRange': {
                                                                                    'start': rangeStartController.text.isEmpty ? '0.00' : rangeStartController.text,
                                                                                    'end': rangeEndController.text.isEmpty ? '0.00' : rangeEndController.text,
                                                                                  },
                                                                                },
                                                                              ),
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
                                                      if (value != null) {
                                                        setState(() {
                                                          priceData = value;
                                                        });
                                                      }
                                                    });
                                                  },
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text('范围'),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 60,
                                                child: InkWell(
                                                  onTap: () async {
                                                    Navigator.pop(context);
                                                    setState(() {
                                                      priceData = PriceData(type: "pending");
                                                    });
                                                  },
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text('待定'),
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
                                title: const Text("价格"),
                                trailing: pricePreview,
                              ),
                              const Divider(),
                              ListTile(
                                onTap: () {
                                  showModalBottomSheet<String>(
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
                                                    Navigator.pop(context, "屯溪路");
                                                  },
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text('屯溪路'),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 60,
                                                child: InkWell(
                                                  onTap: () async {
                                                    Navigator.pop(context, "翡翠湖");
                                                  },
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text('翡翠湖'),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 60,
                                                child: InkWell(
                                                  onTap: () async {
                                                    Navigator.pop(context, "宣城");
                                                  },
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text('宣城'),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 60,
                                                child: InkWell(
                                                  onTap: () async {
                                                    Navigator.pop(context, "");
                                                  },
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text('不选择'),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ).toList(),
                                        ),
                                      );
                                    },
                                  ).then((value) {
                                    if (value != null) {
                                      setState(() {
                                        if (value == "") {
                                          campus = null;
                                        } else {
                                          campus = value;
                                        }
                                      });
                                    }
                                  });
                                },
                                title: const Text("校区"),
                                trailing: Text(
                                  campus ?? "未选择",
                                  style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.outline),
                                ),
                              ),
                              const Divider(),
                              ListTile(
                                onTap: () {
                                  Navigator.push<ChannelData>(
                                    context,
                                    MaterialPageRoute(builder: (context) {
                                      return ChannelSelectPage(
                                        initMainChannel: channelData == null ? null : channelData!.mainChannel,
                                      );
                                    }),
                                  ).then((value) {
                                    setState(() {
                                      channelData = value;
                                    });
                                  });
                                },
                                title: const Text("频道"),
                                trailing: Text(
                                  channelData == null ? "未选择" : channelData.toString(),
                                  style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.outline),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

bool isStringEmpty(String? value) {
  if (value == null) {
    return true;
  } else {
    List<String> keys = value.split(
      RegExp(r" +"),
    );
    keys.removeWhere((element) => element == "");

    return keys.isEmpty;
  }
}

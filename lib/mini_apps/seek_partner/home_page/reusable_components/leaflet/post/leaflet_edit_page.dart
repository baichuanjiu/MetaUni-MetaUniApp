import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/reusable_components/leaflet/post/label_preview.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/reusable_components/leaflet/post/leaflet_post_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../../../reusable_components/gallery/function/pick_multiple_images_modal.dart';
import '../../../../../../reusable_components/route_animation/route_animation.dart';
import '../../../../../../reusable_components/snack_bar/no_permission_snack_bar.dart';
import '../../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import 'media_preview.dart';
import 'tag_preview.dart';

class SelectedAsset {
  final DateTime timestamp;
  final AssetEntity asset;

  SelectedAsset({required this.timestamp, required this.asset});
}

class CameraMedia {
  final DateTime timestamp;
  final XFile media;

  CameraMedia({required this.timestamp, required this.media});
}

class LeafletEditPage extends StatefulWidget {
  const LeafletEditPage({
    super.key,
  });

  @override
  State<LeafletEditPage> createState() => _LeafletEditPageState();
}

class _LeafletEditPageState extends State<LeafletEditPage> {
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
              onRemove: () {
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
              onRemove: () {
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
          onRemove: () {
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
          onRemove: () {
            cameraMedias.remove(current);
            updateMediaPreviewList();
          },
        ),
      );
    }

    setState(() {});
  }

  final formKey = GlobalKey<FormState>();

  String title = '';
  final TextEditingController titleController = TextEditingController();
  final FocusNode titleFocusNode = FocusNode();

  String description = '';
  final TextEditingController descriptionController = TextEditingController();
  final FocusNode descriptionFocusNode = FocusNode();

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

  List<String> tags = [];
  List<TagPreview> tagPreviewList = [];

  updateTagPreviewList() {
    tagPreviewList.clear();
    for (var tag in tags) {
      tagPreviewList.add(
        TagPreview(
          tag: tag,
          onRemove: () {
            tags.remove(tag);
            updateTagPreviewList();
          },
        ),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Center(
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            child: TextButton(
              onPressed: (isStringEmpty(titleController.text) || isStringEmpty(descriptionController.text))
                  ? null
                  : () {
                      if (formKey.currentState!.validate()) {
                        Navigator.push(
                          context,
                          routeFromBottom(
                            page: LeafletPostPage(title: title, description: description, labels: labels, tags: tags, medias: medias),
                          ),
                        );
                      }
                    },
              child: const Text("下一步"),
            ),
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
              child: Form(
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
                        maxLength: 25,
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
                          hintText: "正文",
                        ),
                        minLines: 3,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        maxLength: 200,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (isStringEmpty(value)) {
                            return ' 正文 不能为空';
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
                    labels.isEmpty
                        ? Container()
                        : Text(
                            "标签",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: labelPreviewList,
                    ),
                    tags.isEmpty
                        ? Container()
                        : Text(
                            "Tag",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                      child: Wrap(
                        children: tagPreviewList,
                      ),
                    ),
                    medias.isEmpty
                        ? Container()
                        : Text(
                            "媒体文件",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                    mediaPreviewList.isEmpty
                        ? Container()
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: mediaPreviewList.length == 1
                                  ? Stack(
                                      children: [
                                        Image.file(
                                          medias[0],
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: GestureDetector(
                                            onTap: () {
                                              if (selectedAssets.isNotEmpty) {
                                                selectedAssets.removeAt(0);
                                              } else {
                                                cameraMedias.removeAt(0);
                                              }
                                              updateMediaPreviewList();
                                            },
                                            child: CircleAvatar(
                                              backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                                              radius: 10,
                                              child: Icon(
                                                Icons.close_outlined,
                                                color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : mediaPreviewList.length == 2 || mediaPreviewList.length == 4
                                      ? AspectRatio(
                                          aspectRatio: 4 / mediaPreviewList.length,
                                          child: GridView.count(
                                            physics: const NeverScrollableScrollPhysics(),
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 2,
                                            crossAxisSpacing: 2,
                                            children: [...mediaPreviewList],
                                          ),
                                        )
                                      : AspectRatio(
                                          aspectRatio: 1 / ((mediaPreviewList.length / 3).ceil() / 3),
                                          child: GridView.count(
                                            physics: const NeverScrollableScrollPhysics(),
                                            crossAxisCount: 3,
                                            mainAxisSpacing: 2,
                                            crossAxisSpacing: 2,
                                            children: [...mediaPreviewList],
                                          ),
                                        ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
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
                      icon: Icon(
                        Icons.photo_camera_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (await Permission.photos.request().isGranted) {
                          if (mounted) {
                            List<AssetEntity> assets = selectedAssets.map((e) => e.asset).toList();

                            assets = await pickMultipleImagesModal(context: context, selectedAssets: assets, maxCount: 9 - cameraMedias.length);

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
                      icon: Icon(
                        Icons.image_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
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
                                                  text: "添加的标签将以",
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                                TextSpan(
                                                  text: " “关键词 内容” ",
                                                  style: Theme.of(context).textTheme.bodyLarge,
                                                ),
                                                TextSpan(
                                                  text: "的形式在 详情页 展示，清晰简洁的标签有助于其他用户快速提取要点。",
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
                      icon: Icon(
                        Icons.new_label_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final formKey = GlobalKey<FormState>();
                        final TextEditingController tagController = TextEditingController();
                        final FocusNode tagFocusNode = FocusNode();

                        showModalBottomSheet<String>(
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
                                                "添加Tag",
                                                style: Theme.of(context).textTheme.titleLarge,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(0, 5, 0, 10),
                                          child: Text(
                                            "添加的 Tag 将在 预览页 与 详情页 展示，添加 Tag 带来的额外信息有助于发现志同道合的朋友。",
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ),
                                        Form(
                                          key: formKey,
                                          child: Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                                                child: TextFormField(
                                                  controller: tagController,
                                                  focusNode: tagFocusNode,
                                                  autofocus: true,
                                                  decoration: const InputDecoration(
                                                    border: OutlineInputBorder(),
                                                    filled: true,
                                                    labelText: "Tag",
                                                  ),
                                                  maxLength: 25,
                                                  maxLines: 1,
                                                  textInputAction: TextInputAction.done,
                                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                                  validator: (value) {
                                                    if (isStringEmpty(value)) {
                                                      return ' Tag 不能为空';
                                                    }
                                                    return null;
                                                  },
                                                  onTapOutside: (details) {
                                                    tagFocusNode.unfocus();
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
                                                          tagController.text,
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
                        ).then(
                          (value) {
                            if (value != null) {
                              tags.add(value);
                              updateTagPreviewList();
                            }
                          },
                        );
                      },
                      icon: Icon(
                        Icons.tag_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

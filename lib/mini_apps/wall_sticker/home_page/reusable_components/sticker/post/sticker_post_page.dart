import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta_uni_app/database/models/user/brief_user_information.dart';
import 'package:meta_uni_app/reusable_components/gallery/function/pick_multiple_medias_modal.dart';
import 'package:meta_uni_app/reusable_components/get_current_user_information/get_current_user_information.dart';
import 'package:meta_uni_app/reusable_components/snack_bar/normal_snack_bar.dart';
import 'package:meta_uni_app/reusable_components/sticker/sticker_manager.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';
import '../../../../../../../reusable_components/logout/logout.dart';
import '../../../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../../../reusable_components/snack_bar/no_permission_snack_bar.dart';
import '../../../../../../../reusable_components/special_text/custom_text_span_builder.dart';
import '../../../../../mini_app_manager.dart';
import '../../tag/tags.dart';
import '../models/reply_info.dart';
import '../models/sticker_data.dart';
import '../sticker/sticker.dart';
import 'emoji_box.dart';
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

class AnonymousInfo {
  late String avatar;
  late String nickname;

  AnonymousInfo({required this.avatar, required this.nickname});

  AnonymousInfo.fromJson(Map<String, dynamic> map) {
    avatar = map['avatar'];
    nickname = map['nickname'];
  }
}

class StickerPostPage extends StatefulWidget {
  final ReplyInfo? replyInfo;

  const StickerPostPage({super.key, this.replyInfo});

  @override
  State<StickerPostPage> createState() => _StickerPostPageState();
}

class _StickerPostPageState extends State<StickerPostPage> with TickerProviderStateMixin {
  late Dio dio;

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  late final String? jwt;
  late final int? uuid;

  final ScrollController _scrollController = ScrollController();
  Key centerKey = const Key("centerKey");
  bool shouldShowFab = false;

  List<StickerData> timeLineDataList = [];
  int timeLineOffset = 0;
  bool timeLineIsLoading = false;
  bool timeLineHasMore = true;

  _getTimeLineByOffset() async {
    timeLineIsLoading = true;
    timeLineHasMore = false;

    try {
      Response response;
      response = await dio.get(
        '/wallSticker/stickerAPI/sticker/timeLine/replying/${widget.replyInfo!.replyStickerId}/$timeLineOffset',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> tempDataList = response.data['data']['dataList'];
          for (var data in tempDataList) {
            timeLineDataList.add(StickerData.fromJson(data));
          }
          timeLineOffset += tempDataList.length;
          if (tempDataList.length < 20) {
            timeLineHasMore = false;
          }
          else
          {
            timeLineHasMore = true;
          }
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
          //Message:"您正在对一个不存在的贴贴的时间线进行查询"
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

    timeLineIsLoading = false;
  }

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

  bool isEditingTags = false;
  TextEditingController contentController = TextEditingController();
  FocusNode contentFocusNode = FocusNode();
  FocusScopeNode focusScopeNode = FocusScopeNode();
  List<String> tags = [];
  List<TextEditingController> tagControllers = [];
  List<Widget> tagInputFields = [];

  updateTagInputFields() {
    List<TextEditingController> tempList = [];
    tags.clear();
    for (int i = 0; i < tagControllers.length; i++) {
      if (tagControllers[i].text.isNotEmpty) {
        tempList.add(tagControllers[i]);
        tags.add(tagControllers[i].text);
      }
    }
    int delta = 2 - tempList.length;
    for (int i = 0; i < delta; i++) {
      tempList.add(TextEditingController());
    }
    tagControllers = tempList;
    generateTagInputFields();
  }

  generateTagInputFields() {
    tagInputFields.clear();
    for (int i = 0; i < tagControllers.length; i++) {
      if (i != tagControllers.length - 1) {
        tagInputFields.add(
          Container(
            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                    child: TextField(
                      controller: tagControllers[i],
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'tag${i + 1}',
                      ),
                      textInputAction: TextInputAction.next,
                      maxLength: 25,
                      maxLines: 1,
                      onTapOutside: (event) {
                        focusScopeNode.unfocus();
                      },
                    ),
                  ),
                ),
                Container(
                  width: 56,
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                ),
              ],
            ),
          ),
        );
      } else {
        tagInputFields.add(
          Container(
            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                    child: TextField(
                      controller: tagControllers[i],
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'tag${i + 1}',
                      ),
                      maxLength: 25,
                      maxLines: 1,
                      onEditingComplete: () {
                        isEditingTags = false;
                        updateTagInputFields();
                      },
                      onTapOutside: (event) {
                        focusScopeNode.unfocus();
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  child: IconButton(
                    onPressed: () {
                      tagControllers.add(TextEditingController());
                      generateTagInputFields();
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  late AnimationController emojiBoxAnimationController;
  late Animation<double> emojiBoxAnimation;
  bool isInputtingEmoji = false;

  late BriefUserInformation user;
  bool isAnonymous = false;
  AnonymousInfo anonymousInfo = AnonymousInfo(avatar: "", nickname: "");

  getAnonymousInfo() async {
    try {
      Response response;
      response = await dio.get(
        '/wallSticker/stickerAPI/sticker/anonymousInfo',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          anonymousInfo = AnonymousInfo.fromJson(response.data['data']);
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

  void postSticker() async {
    setState(() {
      isPosting = true;
      fadeAnimationController.forward();
    });

    isEditingTags = false;
    await updateTagInputFields();

    Map<String, dynamic> formDataMap = {
      'isAnonymous': isAnonymous,
      'replyStickerId': widget.replyInfo?.replyStickerId,
      'text': contentController.text,
      'tags': tags,
    };

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
        '/wallSticker/stickerAPI/sticker',
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
              Navigator.pop(context, true);
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
        //Message:"禁止对不存在或已被删除的贴贴进行操作"
        case 3:
        //Message:"贴贴失败，文字内容不能为空"
        case 4:
        //Message:"贴贴失败，上传文件数超过限制"
        case 5:
          //Message:"贴贴失败，禁止上传规定格式以外的文件"
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
        //Message:"发生错误，贴贴失败"
        case 7:
          //Message:"发生错误，贴贴失败"
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

  late Future<dynamic> init;

  _init() async {
    await _initDio();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    jwt = prefs.getString('jwt');
    uuid = prefs.getInt('uuid');

    updateTagInputFields();
    getAnonymousInfo();

    if (widget.replyInfo != null) {
      _getTimeLineByOffset();
    }

    user = await getCurrentUserInformation();
  }

  @override
  void initState() {
    super.initState();

    init = _init();

    if (widget.replyInfo != null) {
      _scrollController.addListener(() {
        if (_scrollController.offset.abs() >= MediaQuery.of(context).size.height) {
          setState(() {
            shouldShowFab = true;
          });
        } else {
          setState(() {
            shouldShowFab = false;
          });
        }
        if (_scrollController.position.extentBefore < 300 && !timeLineIsLoading && timeLineHasMore) {
          timeLineIsLoading = true;
          _getTimeLineByOffset();
        }
      });
    }

    emojiBoxAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    emojiBoxAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: emojiBoxAnimationController, curve: Curves.ease),
    );

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
    _scrollController.dispose();
    //VideoCompress.deleteAllCache();
    contentFocusNode.dispose();
    for (var controller in tagControllers) {
      controller.dispose();
    }
    focusScopeNode.dispose();
    emojiBoxAnimationController.dispose();
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
                child: FilledButton.tonal(
                  onPressed: contentController.value.text.isEmpty
                      ? null
                      : () {
                          postSticker();
                        },
                  child: const Text("贴贴"),
                ),
              ),
            ],
          ),
          floatingActionButton: shouldShowFab
              ? Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 56),
                  child: FloatingActionButton(
                    onPressed: () {
                      _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.ease);
                    },
                    child: _scrollController.offset >= 0
                        ? const Icon(
                            Icons.arrow_upward,
                          )
                        : const Icon(
                            Icons.arrow_downward,
                          ),
                  ),
                )
              : null,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          controller: _scrollController,
                          center: centerKey,
                          slivers: [
                            widget.replyInfo != null
                                ? SliverList.builder(
                                    itemCount: timeLineDataList.length,
                                    itemBuilder: (context, index) {
                                      return Sticker(
                                        stickerData: timeLineDataList[index],
                                        isInTimeLine: true,
                                        disableTap: true,
                                        disableCopyText: false,
                                      );
                                    },
                                  )
                                : const SliverToBoxAdapter(),
                            SliverPadding(
                              padding: EdgeInsets.zero,
                              key: centerKey,
                            ),
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(10, widget.replyInfo != null ? 0 : 10, 10, 0),
                              sliver: SliverToBoxAdapter(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        widget.replyInfo != null
                                            ? Container(
                                                height: 10,
                                                width: 2,
                                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.25),
                                              )
                                            : Container(),
                                        Avatar(isAnonymous ? anonymousInfo.avatar : user.avatar),
                                      ],
                                    ),
                                    Container(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.fromLTRB(5, widget.replyInfo != null ? 10 : 0, 0, 0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                widget.replyInfo != null
                                                    ? RichText(
                                                        text: TextSpan(
                                                          children: [
                                                            TextSpan(
                                                              text: "回复",
                                                              style: Theme.of(context).textTheme.bodyMedium,
                                                            ),
                                                            TextSpan(
                                                              text: " @${widget.replyInfo!.replyTo}",
                                                              style: Theme.of(context).textTheme.bodyMedium?.apply(color: Theme.of(context).colorScheme.primary),
                                                            ),
                                                          ],
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      )
                                                    : Container(),
                                                Text(
                                                  isAnonymous ? anonymousInfo.nickname : user.nickname,
                                                  style: Theme.of(context).textTheme.bodyLarge,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                )
                                              ],
                                            ),
                                          ),
                                          ExtendedTextField(
                                            autofocus: true,
                                            specialTextSpanBuilder: CustomTextSpanBuilder(stickerUrlPrefix: StickerManager().getStickerUrlPrefix()),
                                            strutStyle: const StrutStyle(),
                                            controller: contentController,
                                            focusNode: contentFocusNode,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(borderSide: BorderSide.none),
                                              hintText: "请问您今天要来点兔子吗？",
                                            ),
                                            onTapOutside: (event) {
                                              contentFocusNode.unfocus();
                                            },
                                            maxLines: null,
                                            onChanged: (value) {
                                              setState(() {});
                                            },
                                          ),
                                          isEditingTags
                                              ? Container(
                                                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                                                  child: Stack(
                                                    children: [
                                                      Card(
                                                        elevation: 0,
                                                        shape: RoundedRectangleBorder(
                                                          side: BorderSide(
                                                            color: Theme.of(context).colorScheme.outline,
                                                          ),
                                                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                                                        ),
                                                        child: Container(
                                                          padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                child: FocusScope(
                                                                  node: focusScopeNode,
                                                                  child: Column(
                                                                    children: [
                                                                      ...tagInputFields,
                                                                      Divider(
                                                                        color: Theme.of(context).colorScheme.outline,
                                                                      ),
                                                                      TextButton(
                                                                        onPressed: () {
                                                                          isEditingTags = false;
                                                                          updateTagInputFields();
                                                                        },
                                                                        child: const Text("确定"),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 10,
                                                        right: 10,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              isEditingTags = false;
                                                              updateTagInputFields();
                                                            });
                                                          },
                                                          child: CircleAvatar(
                                                            backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.8),
                                                            radius: 12,
                                                            child: Icon(
                                                              Icons.close_outlined,
                                                              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                                              size: 20,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : Container(
                                                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                                                  child: Tags(tags: tags),
                                                ),
                                          Container(
                                            constraints: BoxConstraints(
                                              maxHeight: MediaQuery.of(context).size.height * 0.25,
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: SingleChildScrollView(
                                                      physics: const AlwaysScrollableScrollPhysics(
                                                        parent: BouncingScrollPhysics(),
                                                      ),
                                                      scrollDirection: Axis.horizontal,
                                                      child: Row(
                                                        children: mediaPreviewList,
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
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  isAnonymous = !isAnonymous;
                                });
                              },
                              icon: Icon(
                                isAnonymous ? Icons.public_outlined : Icons.vpn_lock_outlined,
                              ),
                              label: Text(isAnonymous ? "取消匿名" : "匿名贴贴"),
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
                                        if (medias.length < 4) {
                                          if (await Permission.camera.request().isGranted) {
                                            if (mounted) {
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) => AlertDialog(
                                                  content: SizedBox(
                                                    height: 64,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Center(
                                                            child: InkWell(
                                                              onTap: () async {
                                                                Navigator.pop(context);
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
                                                              },
                                                              borderRadius: BorderRadius.circular(15),
                                                              child: Container(
                                                                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                                                child: const Column(
                                                                  children: [
                                                                    Icon(
                                                                      Icons.camera_outlined,
                                                                    ),
                                                                    Text("拍摄"),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const VerticalDivider(),
                                                        Expanded(
                                                          child: Center(
                                                            child: InkWell(
                                                              onTap: () async {
                                                                Navigator.pop(context);
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
                                                              },
                                                              borderRadius: BorderRadius.circular(15),
                                                              child: Container(
                                                                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                                                child: const Column(
                                                                  children: [
                                                                    Icon(
                                                                      Icons.videocam_outlined,
                                                                    ),
                                                                    Text("录像"),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          } else {
                                            if (mounted) {
                                              getPermissionDeniedSnackBar(context, '未获得相机使用权限');
                                            }
                                          }
                                        } else {
                                          getNormalSnackBar(context, "最多仅可上传 4 项媒体文件");
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

                                            assets = await pickMultipleMediasModal(context: context, selectedAssets: assets, maxCount: 4 - cameraMedias.length);

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
                                      onPressed: () async {
                                        if (isInputtingEmoji) {
                                          await emojiBoxAnimationController.reverse();
                                        } else {
                                          emojiBoxAnimationController.forward();
                                        }
                                        setState(() {
                                          isInputtingEmoji = !isInputtingEmoji;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.add_reaction_outlined,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          isEditingTags = !isEditingTags;
                                          updateTagInputFields();
                                        });
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
                          SizeTransition(
                            axis: Axis.vertical,
                            sizeFactor: emojiBoxAnimation,
                            child: TapRegion(
                              onTapOutside: (tap) async {
                                if (isInputtingEmoji) {
                                  await emojiBoxAnimationController.reverse();
                                  setState(() {
                                    isInputtingEmoji = !isInputtingEmoji;
                                  });
                                }
                              },
                              child: EmojiBox(
                                onTapSticker: (String stickerText) {
                                  setState(() {
                                    contentController.text = "${contentController.text}$stickerText";
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
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

class Avatar extends StatelessWidget {
  final String avatar;

  const Avatar(this.avatar, {super.key});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fadeInDuration: const Duration(milliseconds: 800),
      fadeOutDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => CircleAvatar(
        radius: 25,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const CupertinoActivityIndicator(),
      ),
      imageUrl: avatar,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 25,
        backgroundImage: imageProvider,
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: 25,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.error_outline),
      ),
    );
  }
}

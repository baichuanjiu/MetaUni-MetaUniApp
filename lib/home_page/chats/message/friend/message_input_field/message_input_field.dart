import 'dart:io';
import 'dart:ui';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_uni_app/home_page/chats/message/friend/message_input_field/media_preview.dart';
import 'package:meta_uni_app/home_page/chats/message/friend/message_input_field/sticker_box/sticker_box.dart';
import 'package:meta_uni_app/home_page/chats/message/friend/message_input_field/tool_box/tool_box.dart';
import 'package:meta_uni_app/home_page/chats/message/friend/models/message_input_data.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../../reusable_components/gallery/view/reusable_components/selected_assets_bloc.dart';
import '../../../../../reusable_components/special_text/custom_text_span_builder.dart';
import '../../../../../reusable_components/sticker/sticker_manager.dart';

class MessageInputField extends StatefulWidget {
  final void Function() removeContextMenu;
  final void Function(MessageInputData) sendMessage;

  const MessageInputField({super.key, required this.removeContextMenu, required this.sendMessage});

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> with TickerProviderStateMixin {
  bool isOpeningExpandableArea = false;
  bool isInputtingSticker = false;
  bool isRecordingVoice = false;
  bool isOpeningToolbox = false;

  void sendMessage() async {
    List<File> files = [];
    for (var asset in selectedAssets) {
      files.add((await asset.file)!);
    }

    widget.sendMessage(
      MessageInputData(messageTextController.text, files),
    );
    setState(() {
      messageTextController.clear();
      selectedAssetsCubit.clear();
    });
  }

  void sendCameraMedia(File file) async {
    widget.sendMessage(
      MessageInputData(null, [file]),
    );
  }

  late IconButton micButton = IconButton(
    onPressed: () {
      widget.removeContextMenu();
    },
    icon: Icon(
      Icons.mic_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  late IconButton sendButton = IconButton(
    onPressed: () {
      sendMessage();
    },
    icon: Icon(
      Icons.send,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  late StickerBox stickerBox = StickerBox(
    onTapSticker: (String stickerText) {
      setState(() {
        messageTextController.text = "${messageTextController.text}$stickerText";
      });
    },
  );
  late Toolbox toolbox = Toolbox(
    sendMessage: sendMessage,
    sendCameraMedia: sendCameraMedia,
  );
  Container container = Container();
  late Widget areaContent = container;

  late AnimationController expandableAreaAnimationController;
  late Animation<double> expandableAreaAnimation;

  FocusNode messageTextFocusNode = FocusNode();
  TextEditingController messageTextController = TextEditingController();

  late int lastSelectedAssetsCount = 0;
  late AnimationController selectedAssetsAnimationController;
  late Animation<double> selectedAssetsAnimation;
  late List<AssetEntity> selectedAssets = [];
  late SelectedAssetsCubit selectedAssetsCubit = SelectedAssetsCubit(selectedAssets);

  @override
  void initState() {
    super.initState();

    messageTextFocusNode.addListener(() async {
      if (messageTextFocusNode.hasFocus) {
        if (isOpeningExpandableArea) {
          await expandableAreaAnimationController.reverse();
          setState(() {
            isOpeningExpandableArea = false;
            isInputtingSticker = false;
            isOpeningToolbox = false;
            isRecordingVoice = false;
          });
        }
      }
    });
    expandableAreaAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    expandableAreaAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: expandableAreaAnimationController, curve: Curves.ease),
    );

    selectedAssetsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    selectedAssetsAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: selectedAssetsAnimationController, curve: Curves.ease),
    );
  }

  @override
  void dispose() {
    messageTextFocusNode.dispose();
    messageTextController.dispose();
    expandableAreaAnimationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool canSend = messageTextController.text.isNotEmpty || selectedAssets.isNotEmpty;

    List<MediaPreview> mediaPreviewList = [];
    for (var asset in selectedAssets) {
      mediaPreviewList.add(
        MediaPreview(
          asset: asset,
          isVideo: asset.type == AssetType.video,
          remove: () {
            selectedAssetsCubit.remove(asset);
          },
        ),
      );
    }

    if (lastSelectedAssetsCount == 0 && selectedAssets.isNotEmpty) {
      selectedAssetsAnimationController.forward();
    } else if (lastSelectedAssetsCount > 0 && selectedAssets.isEmpty) {
      selectedAssetsAnimationController.reverse();
    }

    lastSelectedAssetsCount = selectedAssets.length;

    return BlocProvider<SelectedAssetsCubit>.value(
      value: selectedAssetsCubit,
      child: TapRegion(
        onTapOutside: (tap) async {
          if (isOpeningExpandableArea) {
            await expandableAreaAnimationController.reverse();
            setState(() {
              isOpeningExpandableArea = false;
              isInputtingSticker = false;
              isOpeningToolbox = false;
              isRecordingVoice = false;
              areaContent = container;
            });
          }
        },
        child: Column(
          children: [
            BlocListener<SelectedAssetsCubit, List<AssetEntity>>(
              listener: (context, newAssets) {
                setState(() {
                  selectedAssets = newAssets;
                });
              },
              child: SizeTransition(
                axis: Axis.vertical,
                sizeFactor: selectedAssetsAnimation,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(7.5, 10, 10, 7.5),
                    height: 220,
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.8),
                    child: Stack(
                      children: [
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                          child: Container(),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(
                maxHeight: 100,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      widget.removeContextMenu();

                      if (isOpeningExpandableArea) {
                        if (isOpeningToolbox) {
                          expandableAreaAnimationController.reverse().then((value) {
                            setState(() {
                              isOpeningExpandableArea = false;
                              isInputtingSticker = false;
                              isOpeningToolbox = false;
                              isRecordingVoice = false;
                              areaContent = container;
                            });
                          });
                        } else {
                          setState(() {
                            isInputtingSticker = false;
                            isOpeningToolbox = true;
                            isRecordingVoice = false;
                            areaContent = toolbox;
                          });
                        }
                      } else {
                        setState(() {
                          isOpeningExpandableArea = true;
                          isInputtingSticker = false;
                          isOpeningToolbox = true;
                          isRecordingVoice = false;
                          areaContent = toolbox;
                        });
                        expandableAreaAnimationController.forward();
                      }
                    },
                    icon: Icon(
                      isOpeningToolbox ? Icons.add_circle_rounded : Icons.add_circle_outline,
                      color: isOpeningToolbox ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      widget.removeContextMenu();

                      if (isOpeningExpandableArea) {
                        if (isInputtingSticker) {
                          expandableAreaAnimationController.reverse().then((value) {
                            setState(() {
                              isOpeningExpandableArea = false;
                              isInputtingSticker = false;
                              isOpeningToolbox = false;
                              isRecordingVoice = false;
                              areaContent = container;
                            });
                          });
                        } else {
                          setState(() {
                            isInputtingSticker = true;
                            isOpeningToolbox = false;
                            isRecordingVoice = false;
                            areaContent = stickerBox;
                          });
                        }
                      } else {
                        setState(() {
                          isOpeningExpandableArea = true;
                          isInputtingSticker = true;
                          isOpeningToolbox = false;
                          isRecordingVoice = false;
                          areaContent = stickerBox;
                        });
                        expandableAreaAnimationController.forward();
                      }
                    },
                    icon: Icon(
                      isInputtingSticker ? Icons.emoji_emotions_rounded : Icons.emoji_emotions_outlined,
                      color: isInputtingSticker ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Expanded(
                    child: ExtendedTextField(
                      specialTextSpanBuilder: CustomTextSpanBuilder(stickerUrlPrefix: StickerManager().getStickerUrlPrefix()),
                      strutStyle: const StrutStyle(),
                      focusNode: messageTextFocusNode,
                      controller: messageTextController,
                      decoration: InputDecoration(
                        filled: true,
                        border: const OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                        suffixIcon: canSend ? sendButton : micButton,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      onTap: () {
                        widget.removeContextMenu();
                      },
                      onTapOutside: (value) {
                        messageTextFocusNode.unfocus();
                      },
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizeTransition(
              axis: Axis.vertical,
              sizeFactor: expandableAreaAnimation,
              child: Container(
                height: 256,
                width: double.infinity,
                color: Theme.of(context).colorScheme.surface,
                child: areaContent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

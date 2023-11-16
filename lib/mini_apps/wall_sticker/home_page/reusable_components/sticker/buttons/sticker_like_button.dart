import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:like_button/like_button.dart';
import 'package:meta_uni_app/mini_apps/wall_sticker/home_page/bloc/like_button_status/like_button_status_bloc.dart';
import 'package:meta_uni_app/mini_apps/wall_sticker/home_page/bloc/wall_sticker_bloc_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../../reusable_components/formatter/number_formatter/number_formatter.dart';
import '../../../../../../../reusable_components/logout/logout.dart';
import '../../../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../../mini_app_manager.dart';
import '../../../bloc/like_button_status/models/like_button_status.dart';

class StickerLikeButton extends StatefulWidget {
  final String id;
  final bool isDeleted;
  final bool isLiked;
  final int likesNumber;
  final bool isOnlyIcon;

  const StickerLikeButton({super.key, required this.id, required this.isDeleted, required this.isLiked, required this.likesNumber, this.isOnlyIcon = false});

  @override
  State<StickerLikeButton> createState() => _StickerLikeButtonState();
}

class _StickerLikeButtonState extends State<StickerLikeButton> {
  late bool isLiked = widget.isLiked;
  late int likesNumber = widget.likesNumber;

  Future<bool> changeLikeStatus() async {
    Dio dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );

    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dio.put(
        '/wallSticker/stickerAPI/sticker/like/${widget.id}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          LikeButtonStatus likeButtonStatus = LikeButtonStatus(response.data['data']['isLiked'], response.data['data']['likesNumber']);
          WallStickerBlocManager().likeButtonStatusCubit.shouldUpdate(
            MapEntry(
              widget.id,
              likeButtonStatus,
            ),
          );
          return true;
          // break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
          //Message:"您无法对一个不存在或已删除的Sticker进行操作"
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

    return false;
  }

  Future<bool> onLikeButtonTapped(bool isLiked) async {
    if (widget.isDeleted) {
      return isLiked;
    }

    final bool success = await changeLikeStatus();

    return success ? !isLiked : isLiked;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOnlyIcon) {
      return BlocProvider.value(
        value: WallStickerBlocManager().likeButtonStatusCubit,
        child: BlocConsumer<LikeButtonStatusCubit, Map<String, LikeButtonStatus>>(
          listener: (context, map) {
            if (map.containsKey(widget.id)) {
              if (isLiked != map[widget.id]!.isLiked) {
                setState(() {
                  isLiked = map[widget.id]!.isLiked;
                });
              }
            }
          },
          builder: (context, map) {
            if (map.containsKey(widget.id)) {
              isLiked = map[widget.id]!.isLiked;
            } else {
              isLiked = widget.isLiked;
            }

            return LikeButton(
              onTap: onLikeButtonTapped,
              size: 50,
              circleColor: CircleColor(
                start: Theme.of(context).colorScheme.secondary,
                end: Theme.of(context).colorScheme.primary,
              ),
              bubblesColor: BubblesColor(
                dotPrimaryColor: Theme.of(context).colorScheme.secondary,
                dotSecondaryColor: Theme.of(context).colorScheme.primary,
              ),
              isLiked: isLiked,
              likeBuilder: (bool isLiked) {
                return Icon(
                  isLiked ? Icons.favorite : Icons.favorite_outline,
                  color: isLiked ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                  size: 32,
                );
              },
              likeCount: null,
            );
          },
        ),
      );
    }

    return BlocProvider.value(
      value: WallStickerBlocManager().likeButtonStatusCubit,
      child: BlocConsumer<LikeButtonStatusCubit, Map<String, LikeButtonStatus>>(
        listener: (context, map) {
          if (map.containsKey(widget.id)) {
            if (isLiked != map[widget.id]!.isLiked || likesNumber != map[widget.id]!.likesNumber) {
              setState(() {
                isLiked = map[widget.id]!.isLiked;
                likesNumber = map[widget.id]!.likesNumber;
              });
            }
          }
        },
        builder: (context, map) {
          if (map.containsKey(widget.id)) {
            isLiked = map[widget.id]!.isLiked;
            likesNumber = map[widget.id]!.likesNumber;
          } else {
            isLiked = widget.isLiked;
            likesNumber = widget.likesNumber;
          }

          return LikeButton(
            likeCountAnimationType: likesNumber >= 1000 ? LikeCountAnimationType.all : LikeCountAnimationType.part,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            likeCountPadding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
            onTap: onLikeButtonTapped,
            size: 26,
            circleColor: CircleColor(
              start: Theme.of(context).colorScheme.secondary,
              end: Theme.of(context).colorScheme.primary,
            ),
            bubblesColor: BubblesColor(
              dotPrimaryColor: Theme.of(context).colorScheme.secondary,
              dotSecondaryColor: Theme.of(context).colorScheme.primary,
            ),
            isLiked: isLiked,
            likeBuilder: (bool isLiked) {
              return Icon(
                isLiked ? Icons.favorite : Icons.favorite_outline,
                color: isLiked ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                size: 16,
              );
            },
            likeCount: likesNumber,
            countBuilder: (int? count, bool isLiked, String text) {
              if (count == null) {
                return Container();
              } else {
                return Text(
                  getFormattedInt(count),
                  style: Theme.of(context).textTheme.labelSmall?.apply(
                        color: isLiked ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                      ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

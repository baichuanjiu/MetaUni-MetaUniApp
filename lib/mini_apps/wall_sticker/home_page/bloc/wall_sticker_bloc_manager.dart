import 'package:meta_uni_app/mini_apps/wall_sticker/home_page/bloc/like_button_status/like_button_status_bloc.dart';

//单例模式构建WallStickerBlocManager
class WallStickerBlocManager {
  static final WallStickerBlocManager _instance = WallStickerBlocManager._();

  WallStickerBlocManager._();

  factory WallStickerBlocManager() {
    return _instance;
  }

  final LikeButtonStatusCubit likeButtonStatusCubit = LikeButtonStatusCubit({});
}
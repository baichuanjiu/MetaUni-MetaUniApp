import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_uni_app/mini_apps/wall_sticker/home_page/bloc/like_button_status/models/like_button_status.dart';

class LikeButtonStatusCubit extends Cubit<Map<String, LikeButtonStatus>> {
  LikeButtonStatusCubit(super.initialState);

  void shouldUpdate(MapEntry<String,LikeButtonStatus> entry) {
    state.addEntries([entry]);
    Map<String, LikeButtonStatus> map = {};
    map.addAll(state);
    return emit(map);
  }
}

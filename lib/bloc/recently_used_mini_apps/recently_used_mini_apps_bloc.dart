import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_uni_app/database/models/mini_app/brief_mini_app_information.dart';

class RecentlyUsedMiniAppsCubit extends Cubit<BriefMiniAppInformation?> {
  RecentlyUsedMiniAppsCubit(super.initialState);

  void shouldUpdate(BriefMiniAppInformation? info) => emit(info);
}
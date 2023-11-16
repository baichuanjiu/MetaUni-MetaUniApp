import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database/models/chat/common_chat_status.dart';

class CommonChatStatusCubit extends Cubit<CommonChatStatus?> {
  CommonChatStatusCubit(super.initialState);

  void shouldUpdate(CommonChatStatus commonChatStatus) => emit(commonChatStatus);
}
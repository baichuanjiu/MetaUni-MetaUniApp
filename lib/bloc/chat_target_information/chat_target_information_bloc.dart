import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_uni_app/bloc/chat_target_information/models/chat_target_information_update_data.dart';

class ChatTargetInformationCubit extends Cubit<ChatTargetInformationUpdateData?> {
  ChatTargetInformationCubit(super.initialState);

  void shouldUpdate(ChatTargetInformationUpdateData chatTargetInformationUpdateData) => emit(chatTargetInformationUpdateData);
}
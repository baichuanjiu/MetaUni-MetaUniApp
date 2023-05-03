import 'package:flutter_bloc/flutter_bloc.dart';
import 'models/chat_list_tile_update_data.dart';

class ChatListTileCubit extends Cubit<ChatListTileUpdateData?> {
  ChatListTileCubit(super.initialState);

  void shouldUpdate(ChatListTileUpdateData chatListTileUpdateData) => emit(chatListTileUpdateData);
}
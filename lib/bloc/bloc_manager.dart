import 'chat_list_tile/chat_list_tile_bloc.dart';
import 'message/common_message_bloc.dart';
import 'message/total_number_of_unread_messages_bloc.dart';

//单例模式构建BlocManager
class BlocManager {
  static final BlocManager _instance = BlocManager._();

  BlocManager._();

  factory BlocManager() {
    return _instance;
  }

  final CommonMessageCubit commonMessageCubit = CommonMessageCubit(null);
  final TotalNumberOfUnreadMessagesCubit totalNumberOfUnreadMessagesCubit = TotalNumberOfUnreadMessagesCubit();
  final ChatListTileCubit chatListTileDataCubit = ChatListTileCubit(null);
}
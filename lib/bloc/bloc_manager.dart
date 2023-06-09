import 'package:meta_uni_app/bloc/message/common_chat_status_bloc.dart';
import 'chat_list_tile/chat_list_tile_bloc.dart';
import 'contacts/has_unread_add_friend_request_bloc.dart';
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
  final CommonChatStatusCubit commonChatStatusCubit = CommonChatStatusCubit(null);
  final HasUnreadAddFriendRequestCubit hasUnreadAddFriendRequestCubit = HasUnreadAddFriendRequestCubit(false);
}
import 'package:meta_uni_app/bloc/chat_target_information/chat_target_information_bloc.dart';
import 'package:meta_uni_app/bloc/contacts/should_update_contacts_view_bloc.dart';
import 'package:meta_uni_app/bloc/message/common_chat_status_bloc.dart';
import 'package:meta_uni_app/bloc/message/common_message_be_recalled.dart';
import 'package:meta_uni_app/bloc/recently_used_mini_apps/recently_used_mini_apps_bloc.dart';
import 'chat_list_tile/chat_list_tile_bloc.dart';
import 'contacts/has_unread_add_friend_request_bloc.dart';
import 'message/common_message_bloc.dart';
import 'message/system_message_bloc.dart';
import 'message/total_number_of_unread_messages_bloc.dart';

//单例模式构建BlocManager
class BlocManager {
  static final BlocManager _instance = BlocManager._();

  BlocManager._();

  factory BlocManager() {
    return _instance;
  }

  final CommonMessageCubit commonMessageCubit = CommonMessageCubit(null);
  final SystemMessageCubit systemMessageCubit = SystemMessageCubit(null);
  final CommonMessageBeRecalledCubit commonMessageBeRecalledCubit = CommonMessageBeRecalledCubit(null);
  final TotalNumberOfUnreadMessagesCubit totalNumberOfUnreadMessagesCubit = TotalNumberOfUnreadMessagesCubit();
  final ChatListTileCubit chatListTileDataCubit = ChatListTileCubit(null);
  final ChatTargetInformationCubit chatTargetInformationCubit = ChatTargetInformationCubit(null);
  final CommonChatStatusCubit commonChatStatusCubit = CommonChatStatusCubit(null);
  final HasUnreadAddFriendRequestCubit hasUnreadAddFriendRequestCubit = HasUnreadAddFriendRequestCubit(false);
  final ShouldUpdateContactsViewCubit shouldUpdateContactsViewCubit = ShouldUpdateContactsViewCubit(null);
  final RecentlyUsedMiniAppsCubit recentlyUsedMiniAppsCubit = RecentlyUsedMiniAppsCubit(null);
}
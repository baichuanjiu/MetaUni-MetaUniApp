import '../bloc/message/common_message_bloc.dart';

//单例模式构建BlocManager
class BlocManager {
  static final BlocManager _instance = BlocManager._();

  BlocManager._();

  factory BlocManager() {
    return _instance;
  }

  final CommonMessageCubit commonMessageCubit = CommonMessageCubit(null);
}
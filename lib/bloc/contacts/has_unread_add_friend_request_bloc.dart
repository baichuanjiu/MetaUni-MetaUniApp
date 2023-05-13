import 'package:flutter_bloc/flutter_bloc.dart';

class HasUnreadAddFriendRequestCubit extends Cubit<bool> {
  HasUnreadAddFriendRequestCubit(super.initialState);

  void update(bool state) => emit(state);
}

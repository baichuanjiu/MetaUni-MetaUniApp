import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database/models/message/common_message.dart';

class CommonMessageCubit extends Cubit<CommonMessage?> {
  CommonMessageCubit(super.initialState);

  void receive(CommonMessage commonMessage) => emit(commonMessage);
}
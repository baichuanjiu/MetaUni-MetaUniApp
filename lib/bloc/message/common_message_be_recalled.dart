import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database/models/message/common_message.dart';

class CommonMessageBeRecalledCubit extends Cubit<CommonMessage?> {
  CommonMessageBeRecalledCubit(super.initialState);

  void recall(CommonMessage commonMessage) => emit(commonMessage);
}
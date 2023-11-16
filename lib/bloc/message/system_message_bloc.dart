import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database/models/message/system_message.dart';

class SystemMessageCubit extends Cubit<SystemMessage?> {
  SystemMessageCubit(super.initialState);

  void receive(SystemMessage systemMessage) => emit(systemMessage);
}
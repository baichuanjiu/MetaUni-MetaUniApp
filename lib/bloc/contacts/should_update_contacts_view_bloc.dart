import 'package:flutter_bloc/flutter_bloc.dart';
import 'models/should_update_contacts_view_data.dart';

class ShouldUpdateContactsViewCubit extends Cubit<ShouldUpdateContactsViewData?> {
  ShouldUpdateContactsViewCubit(super.initialState);

  void shouldUpdate(ShouldUpdateContactsViewData shouldUpdateContactsViewData) => emit(shouldUpdateContactsViewData);
}
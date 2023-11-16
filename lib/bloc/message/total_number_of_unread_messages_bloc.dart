import 'package:flutter_bloc/flutter_bloc.dart';

class TotalNumberOfUnreadMessagesCubit extends Cubit<int> {
  TotalNumberOfUnreadMessagesCubit() : super(0);

  int get() => state;

  void update(int number) => emit(number);

  void increment(int number) => emit(state + number);

  void decrement(int number) => emit(state - number);
}

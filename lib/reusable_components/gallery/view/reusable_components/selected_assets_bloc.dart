import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';

class SelectedAssetsCubit extends Cubit<List<AssetEntity>> {
  SelectedAssetsCubit(super.initialState);

  void add(AssetEntity asset) {
    List<AssetEntity> newList = [...state, asset];
    return emit(newList);
  }

  void remove(AssetEntity asset) {
    List<AssetEntity> newList = [...state];
    newList.remove(asset);
    return emit(newList);
  }

  void onlyOne(AssetEntity asset) {
    return emit([asset]);
  }

  void replace(List<AssetEntity> newAssets) {
    return emit(newAssets);
  }

  void clear()
  {
    return emit([]);
  }
}

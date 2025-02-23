import 'package:provider_kit/src/base/state_notifier_base.dart';
import 'package:provider_kit/states/view_states.dart';

mixin DataStateCopyCacheMixin<T> on StateNotifierBase<ViewState<T>> {
  DataState<T>? _dataStateCopy;
  T? _dataObjectCopy;

  DataState<T>? get dataStateCopy => _dataStateCopy;
  T? get dataObjectCopy => _dataObjectCopy;

  void saveDataStateCopy(ViewState<T>? newDataState) {
    if (newDataState is DataState<T>) {
      _dataStateCopy = newDataState;
      _dataObjectCopy = newDataState.dataObject;
    }
  }

  void clearDataStateCopy() {
    _dataStateCopy = null;
    _dataObjectCopy = null;
  }

  @override
  void dispose() {
    clearDataStateCopy();
    super.dispose();
  }
}

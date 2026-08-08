import 'package:flutter/foundation.dart';

import '../../core/utils/app_log.dart';
import '../../data/models/assistant_task.dart';
import '../../data/repositories/delivery_repository.dart';
import '../dashboard/master_pos_provider.dart' show LoadState;

/// Backs the assistant (SUB_LOGISTICS_OFFICER) home screen: the flat list of
/// assigned workflow steps from `/assistant/tasks`.
class AssistantTasksProvider extends ChangeNotifier {
  AssistantTasksProvider(this._repo);
  final DeliveryRepository _repo;

  LoadState _state = LoadState.idle;
  List<AssistantTask> _tasks = const [];
  String? _error;

  LoadState get state => _state;
  List<AssistantTask> get tasks => _tasks;
  String? get error => _error;

  Future<void> refresh() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _tasks = await _repo.assistantTasks();
      _state = LoadState.ready;
    } catch (e, st) {
      AppLog.error('AssistantTasksProvider.refresh', e, st);
      _error = e.toString();
      _state = LoadState.error;
    }
    notifyListeners();
  }
}

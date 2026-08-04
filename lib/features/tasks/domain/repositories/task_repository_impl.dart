// lib/features/tasks/domain/repositories/task_repository_impl.dart
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../data/datasources/task_firestore_datasources.dart';
import '../../data/models/task_model.dart';
import '../../../../core/services/auth_services.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskFirestoreDatasource _datasource;
  final AuthService _authService;

  TaskRepositoryImpl(this._datasource, this._authService);

  String get _userId {
    final uid = _authService.currentUserId;
    if (uid == null) throw Exception('User chưa đăng nhập');
    return uid;
  }

  @override
  Future<Task> createTask(Task task) {
    return _datasource.createTask(_userId, TaskModel.fromEntity(task));
  }

  @override
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) {
    return _datasource.updateTask(_userId, taskId, updates);
  }

  @override
  Future<void> deleteTask(String taskId) {
    return _datasource.deleteTask(_userId, taskId);
  }

  @override
  Future<Task?> getTaskById(String taskId) {
    return _datasource.getTaskById(_userId, taskId);
  }

  @override
  Stream<List<Task>> watchTasks({TaskStatus? status}) {
    return _datasource.watchTasks(_userId, status: status);
  }

  @override
  Future<List<Task>> queryTasksByDateRange(DateTime from, DateTime to) {
    return _datasource.queryTasksByDateRange(_userId, from, to);
  }
}
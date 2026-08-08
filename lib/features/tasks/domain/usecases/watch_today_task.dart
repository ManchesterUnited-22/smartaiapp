import '../entities/task.dart';
import '../repositories/task_repository.dart';

class WatchTodayTask {
  final TaskRepository repository;
  WatchTodayTask(this.repository);

  Stream<List<Task>> call() {
    return repository.watchTasks();
  }
}
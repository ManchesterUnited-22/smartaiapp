import '../repositories/task_repository.dart';

class WatchTodayTask {
  final TaskRepository repository;

  WatchTodayTask(this.repository);

  Stream<List<dynamic>> call() {
    return repository.watchTasks();
  }
}

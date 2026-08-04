// lib/features/task/data/datasources/task_firestore_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../../domain/entities/task.dart';

class TaskFirestoreDatasource {
  final FirebaseFirestore _firestore;
  TaskFirestoreDatasource(this._firestore);

  CollectionReference _tasksRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('tasks');

  Future<TaskModel> createTask(String userId, TaskModel task) async {
    final docRef = await _tasksRef(userId).add(task.toFirestore());
    final snapshot = await docRef.get();
    return TaskModel.fromFirestore(snapshot);
  }

  Future<void> updateTask(String userId, String taskId, Map<String, dynamic> updates) async {
    await _tasksRef(userId).doc(taskId).update(updates);
  }

  Future<void> deleteTask(String userId, String taskId) async {
    await _tasksRef(userId).doc(taskId).delete();
  }

  Future<TaskModel?> getTaskById(String userId, String taskId) async {
    final doc = await _tasksRef(userId).doc(taskId).get();
    if (!doc.exists) return null;
    return TaskModel.fromFirestore(doc);
  }

  Stream<List<TaskModel>> watchTasks(String userId, {TaskStatus? status}) {
    Query query = _tasksRef(userId);
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    query = query.orderBy('dueDate');
    return query.snapshots().map(
          (snap) => snap.docs.map((d) => TaskModel.fromFirestore(d)).toList(),
        );
  }

  Future<List<TaskModel>> queryTasksByDateRange(
    String userId,
    DateTime from,
    DateTime to,
  ) async {
    final snap = await _tasksRef(userId)
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('dueDate')
        .get();
    return snap.docs.map((d) => TaskModel.fromFirestore(d)).toList();
  }
}
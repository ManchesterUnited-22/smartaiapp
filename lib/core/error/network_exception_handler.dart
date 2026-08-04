// lib/core/error/network_exception_handler.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NetworkExceptionHandler {
  static String getFriendlyMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
          return 'Không thể kết nối tới máy chủ. Kiểm tra lại mạng và thử lại nhé.';
        case 'permission-denied':
          return 'Bạn không có quyền thực hiện thao tác này.';
        case 'deadline-exceeded':
          return 'Kết nối quá lâu, vui lòng thử lại.';
        default:
          return 'Có lỗi xảy ra khi lưu dữ liệu (${error.code}).';
      }
    }
    return 'Có lỗi không xác định xảy ra, vui lòng thử lại.';
  }
}
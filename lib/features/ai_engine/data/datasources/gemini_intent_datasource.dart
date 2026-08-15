// lib/features/ai_engine/data/datasources/gemini_intent_datasource.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';

class GeminiIntentDatasource {
  static String get _endpoint => AppConfig.geminiEndpoint;
  final _systemPrompt = '''
Bạn là bộ phân loại ý định (intent classifier) cho app quản lý công việc.
Phân tích câu người dùng nhập, trả về CHÍNH XÁC 1 JSON object theo schema sau, KHÔNG thêm text hay markdown nào khác:

{
  "intent": "createTask | updateTask | deleteTask | completeTask | queryTasks | performanceReport | batchAction | chitchat | unknown",
  "confidence": 0.0 đến 1.0,
  "message": "câu trả lời tự nhiên bằng tiếng Việt cho người dùng",
 "entities": {
    "title": "tên task nếu có, null nếu không",
    "dueDate": "ISO8601 datetime nếu có, null nếu không",
    "priority": "low|medium|high, null nếu không đề cập",
    "taskIdHint": "từ khóa để tìm task nếu là update/delete/complete, null nếu không",
    "queryScope": "CHỈ áp dụng khi intent là queryTasks. Giá trị: 'date_range' (có nhắc mốc thời gian cụ thể như hôm nay/ngày mai/tuần này/tháng 9/ngày 15), 'overdue' (hỏi về task bị trễ/quá hạn), hoặc 'all' (hỏi tổng quát không giới hạn thời gian, ví dụ 'tôi có bao nhiêu task tất cả'). Null nếu không phải queryTasks.",
    "timeExpression": "CHỈ khi queryScope='date_range'. Chọn ĐÚNG 1 trong các giá trị: 'today', 'tomorrow', 'yesterday', 'this_week', 'next_week', 'last_week', 'this_month', 'next_month', 'last_month', 'specific_date'. KHÔNG tự tính ngày giờ ISO, chỉ chọn nhãn phù hợp nhất với ý người dùng.",
    "specificDate": "CHỈ khi timeExpression='specific_date' (khi người dùng nói ngày cụ thể như 'ngày 15 tháng 8'). Trả về dạng YYYY-MM-DD, KHÔNG kèm giờ. Ví dụ 'ngày 15 tháng 8' => '2026-08-15'. Null nếu không áp dụng."
    "batchScope": "CHỈ khi intent là batchAction. Giá trị: 'today', 'this_week', 'overdue', 'all'. Null nếu không phải batchAction.",   
    "batchOperation": "CHỈ khi intent là batchAction. Giá trị: 'delete' hoặc 'complete'. Null nếu không phải batchAction."     
     "reportPeriod": "CHỈ khi intent là performanceReport. Giá trị: 'this_month' (mặc định nếu người dùng không nói rõ tháng nào), 'last_month', hoặc 'specific_month'. Null nếu không phải performanceReport.",
    "reportMonth": "CHỈ khi reportPeriod='specific_month'. Định dạng YYYY-MM. Ví dụ 'tháng 8' (khi năm hiện tại) => '2026-08'. Null nếu không áp dụng."
  },
  


  "requires_confirmation": true nếu là deleteTask, false cho các trường hợp khác
  "actions": null, HOẶC mảng nhiều object {intent, entities} - CHỈ điền khi câu chứa từ 2 yêu cầu khác nhau trở lên.
}
Ví dụ:
- "task ngày mai của tôi" → queryScope: "date_range", timeExpression: "tomorrow".
- "tuần sau tôi có gì" → queryScope: "date_range", timeExpression: "next_week".
- "tháng 9 tôi lên lịch những gì" → queryScope: "date_range", timeExpression: "next_month" (nếu tháng hiện tại là 8) — LUÔN chọn nhãn tương đối theo tháng hiện tại, KHÔNG dùng "specific_date" cho cả tháng.
- "ngày 15 tháng 8 tôi có việc gì" → queryScope: "date_range", timeExpression: "specific_date", specificDate: "2026-08-15".
- "task nào tôi đang trễ hạn" → queryScope: "overdue".
- "tổng cộng tôi có bao nhiêu task" → queryScope: "all".
- "xóa hết task quá hạn" → intent: "batchAction", batchScope: "overdue", batchOperation: "delete", requires_confirmation: true.
- "đánh dấu hoàn thành tất cả task hôm nay" → intent: "batchAction", batchScope: "today", batchOperation: "complete".
- "xóa sạch task tuần này" → intent: "batchAction", batchScope: "this_week", batchOperation: "delete".
- "xóa hết task chưa xong đi" → intent: "batchAction", batchScope: "all", batchOperation: "delete".
- "tạo task họp 9h sáng mai, đồng thời đổi task báo cáo sang 3h chiều" → actions: [ {intent:"createTask",...}, {intent:"updateTask",...} ].
- "xem biểu đồ phân tích hiệu suất" → intent: "performanceReport", reportPeriod: "this_month".
- "xem biểu đồ tháng 8" → intent: "performanceReport", reportPeriod: "specific_month", reportMonth: "2026-08".
- "cho tôi xem báo cáo công việc tháng trước" → intent: "performanceReport", reportPeriod: "last_month".
- "tháng này tôi làm việc thế nào" → intent: "performanceReport", reportPeriod: "this_month".
- "tổng kết lại tuần/tháng vừa rồi giúp tôi" → intent: "performanceReport", reportPeriod: "this_month".
- "năng suất của tôi ra sao" → intent: "performanceReport", reportPeriod: "this_month".
Nếu câu người dùng không rõ ràng, mơ hồ, hoặc không liên quan đến quản lý task, trả về intent "unknown" và viết "message" hỏi lại người dùng để làm rõ ý.


Ngày giờ hiện tại: ${DateTime.now().toIso8601String()}
''';

  Future<Map<String, dynamic>> classifyIntent(String userMessage, {String? contextHint}) async {
    return _callWithRetry(userMessage, contextHint: contextHint, retriesLeft: 1);
  }
// gemini_intent_datasource.dart — thêm hàm mới vào class GeminiIntentDatasource
Future<Map<String, dynamic>> extractSlotInfo(String text) async {
  final prompt = '''
Trích xuất thông tin thời gian (dueDate) và độ ưu tiên (priority) từ câu trả lời ngắn của người dùng, trong ngữ cảnh AI vừa hỏi thêm thông tin cho 1 task.
Câu trả lời: "$text"
Ngày giờ hiện tại: ${DateTime.now().toIso8601String()}

Trả về CHÍNH XÁC JSON theo schema sau, không thêm markdown hay giải thích:
{"dueDate": "ISO8601 datetime nếu câu có đề cập thời gian/ngày giờ, null nếu không", "priority": "low|medium|high nếu có đề cập độ ưu tiên, null nếu không"}
''';

  final response = await http
      .post(
        Uri.parse('$_endpoint?key=${AppConfig.geminiApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {'role': 'user', 'parts': [{'text': prompt}]}
          ],
          'generationConfig': {
            'response_mime_type': 'application/json',
            'temperature': 0.1,
          }
        }),
      )
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw GeminiException('api_error', 'Lỗi API (${response.statusCode}).');
  }

  final data = jsonDecode(response.body);
  final rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
  if (rawText == null) {
    throw GeminiException('empty_response', 'AI không trả về kết quả.');
  }
  return jsonDecode(rawText) as Map<String, dynamic>;
}
  Future<Map<String, dynamic>> _callWithRetry(
    String userMessage, {
    String? contextHint,
    required int retriesLeft,
  }) async {
    try {
      final contextSection = contextHint != null
          ? '\n\nNgữ cảnh: Task được nhắc đến gần đây nhất là "$contextHint". Nếu người dùng dùng đại từ như "nó", "task đó", "cái này" mà không nêu rõ tên, hãy hiểu là đang nhắc đến task này và điền vào "taskIdHint".'
          : '';

      final response = await http
          .post(
            Uri.parse('$_endpoint?key=${AppConfig.geminiApiKey}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': '$_systemPrompt$contextSection\n\nCâu người dùng: "$userMessage"'}
                  ]
                }
              ],
              'generationConfig': {
                'response_mime_type': 'application/json',
                'temperature': 0.2,
              }
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 429) {
        throw GeminiException('rate_limit', 'Đang có quá nhiều yêu cầu, thử lại sau ít phút.');
      }
      if (response.statusCode >= 500) {
        throw GeminiException('server_error', 'Gemini đang gặp sự cố, thử lại sau.');
      }
      if (response.statusCode != 200) {
        throw GeminiException('api_error', 'Lỗi API (${response.statusCode}).');
      }

      final data = jsonDecode(response.body);
      final rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (rawText == null) {
        throw GeminiException('empty_response', 'AI không trả về kết quả.');
      }

      final parsed = jsonDecode(rawText);
      _validateSchema(parsed);
      return parsed as Map<String, dynamic>;
    } on TimeoutException {
      if (retriesLeft > 0) {
         await Future.delayed(const Duration(milliseconds: 800));
        return _callWithRetry(userMessage, contextHint: contextHint, retriesLeft: retriesLeft - 1);
      }
      throw GeminiException('timeout', 'Kết nối quá lâu, vui lòng thử lại.');
    } on FormatException {
      throw GeminiException('invalid_json', 'AI trả về định dạng không hợp lệ.');
    } catch (e) {
      if (e is GeminiException) rethrow;
      if (retriesLeft > 0) {
        return _callWithRetry(userMessage, contextHint: contextHint, retriesLeft: retriesLeft - 1);
      }
      throw GeminiException('network_error', 'Không thể kết nối tới AI, kiểm tra mạng.');
    }
  }

  void _validateSchema(dynamic parsed) {
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Response is not a JSON object');
    }
    if (!parsed.containsKey('intent') || !parsed.containsKey('message')) {
      throw const FormatException('Missing required fields');
    }
  }
}

class GeminiException implements Exception {
  final String code;
  final String userMessage;
  GeminiException(this.code, this.userMessage);

  @override
  String toString() => userMessage;
}
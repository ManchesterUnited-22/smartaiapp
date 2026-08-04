// lib/features/analytics/data/datasources/insight_generation_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../domain/entities/performance_report.dart';

class InsightGenerationDatasource {
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<String> generateInsight(PerformanceReport report) async {
    final prompt = '''
Bạn là trợ lý phân tích năng suất làm việc. Dựa vào số liệu sau, viết nhận xét ngắn gọn (3-5 câu) bằng tiếng Việt, có gợi ý cải thiện cụ thể. Không lặp lại số liệu thô, hãy diễn giải ý nghĩa của chúng.

Số liệu:
- Tổng số task: ${report.totalTasks}
- Đã hoàn thành: ${report.completedTasks}
- Trễ hạn: ${report.overdueTasks}
- Tỷ lệ hoàn thành: ${report.completionRate.toStringAsFixed(1)}%
- Phân bố theo tuần: ${report.tasksByWeek}
- Phân bố theo độ ưu tiên: ${report.tasksByPriority}
''';

    final response = await http.post(
      Uri.parse('$_endpoint?key=${AppConfig.geminiApiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {'temperature': 0.4}
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API lỗi: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }
}
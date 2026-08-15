// lib/features/analytics/data/datasources/insight_generation_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../domain/entities/performance_report.dart';

class InsightGenerationDatasource {
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<String> generateInsight(PerformanceReport report) async {
    final punctualityLine = report.avgPunctualityHours == null
        ? '- Đúng giờ trung bình: chưa đủ dữ liệu'
        : report.avgPunctualityHours! >= 0
            ? '- Đúng giờ trung bình: hoàn thành sớm ${report.avgPunctualityHours!.toStringAsFixed(1)} giờ so với hạn'
            : '- Đúng giờ trung bình: trễ ${report.avgPunctualityHours!.abs().toStringAsFixed(1)} giờ so với hạn';

    final comparisonLine = report.previousMonthCompletionRate == null
        ? '- So với tháng trước: chưa có dữ liệu để so sánh'
        : '- So với tháng trước: tháng trước đạt ${report.previousMonthCompletionRate!.toStringAsFixed(1)}%';

    final toneInstruction = report.completionRate >= 80
        ? 'Giọng văn: khen ngợi chân thành, tự nhiên, không sáo rỗng. Ghi nhận cụ thể điểm làm tốt.'
        : report.completionRate >= 50
            ? 'Giọng văn: trung lập, động viên nhẹ nhàng, chỉ ra rõ 1 điểm có thể cải thiện.'
            : 'Giọng văn: ấm áp, khích lệ, TUYỆT ĐỐI không chê trách hay dùng từ tiêu cực nặng. Tập trung vào hướng đi tiếp theo thay vì kết quả hiện tại.';

    final prompt = '''
Bạn là trợ lý phân tích năng suất làm việc. Dựa vào số liệu sau, viết nhận xét ngắn gọn (3-5 câu) bằng tiếng Việt, có gợi ý cải thiện cụ thể. Không lặp lại số liệu thô, hãy diễn giải ý nghĩa của chúng.

$toneInstruction

Số liệu:
- Tổng số task: ${report.totalTasks}
- Đã hoàn thành: ${report.completedTasks}
- Trễ hạn: ${report.overdueTasks}
- Tỷ lệ hoàn thành: ${report.completionRate.toStringAsFixed(1)}%
- Phân bố theo tuần: ${report.tasksByWeek}
- Phân bố theo độ ưu tiên: ${report.tasksByPriority}
$punctualityLine
$comparisonLine
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
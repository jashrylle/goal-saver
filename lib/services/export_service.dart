import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/goal_model.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  String _currencyCode = 'PHP';

  /// Set the currency code (e.g., 'PHP', 'USD', 'EUR', 'GBP')
  void setCurrency(String code) {
    _currencyCode = code;
  }

  String get _currencySymbol {
    switch (_currencyCode) {
      case 'PHP': return '₱';
      case 'USD': return r'$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      default: return '₱';
    }
  }

  String _formatMoney(double value) {
    return '$_currencySymbol${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> exportToPDF(List<SavingsGoal> goals, List<SavingsLog> history, {String currencyCode = 'PHP'}) async {
    _currencyCode = currencyCode;
    final pdf = await _generatePDF(goals, history);
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/goal_saver_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Goal Saver Report',
        text: 'Here is your savings report from Goal Saver',
      ),
    );
  }

  Future<pw.Document> _generatePDF(List<SavingsGoal> goals, List<SavingsLog> history) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Goal Saver Report',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated on ${_formatDate(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 30),
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Summary',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              _buildSummaryTable(goals),
              pw.SizedBox(height: 30),
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Savings Goals',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              ...goals.map((goal) => _buildGoalCard(goal)),
              if (history.isNotEmpty) ...[
                pw.SizedBox(height: 30),
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    'Recent Transactions',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 10),
                ...history.take(10).map((log) => _buildTransactionCard(log)),
              ],
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildSummaryTable(List<SavingsGoal> goals) {
    final totalSaved = goals.fold(0.0, (sum, goal) => sum + goal.saved);
    final totalTarget = goals.fold(0.0, (sum, goal) => sum + goal.target);
    final activeGoals = goals.where((g) => !g.completed && !g.archived && !g.deleted).length;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        _buildTableRow('Total Goals', '${goals.length}', isHeader: true),
        _buildTableRow('Active Goals', '$activeGoals', isHeader: false),
        _buildTableRow('Total Saved', _formatMoney(totalSaved), isHeader: false),
        _buildTableRow('Total Target', _formatMoney(totalTarget), isHeader: false),
        _buildTableRow('Overall Progress', '${((totalSaved / totalTarget) * 100).round()}%', isHeader: false),
      ],
    );
  }

  pw.TableRow _buildTableRow(String label, String value, {bool isHeader = false}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isHeader ? PdfColors.green100 : PdfColors.white,
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(12),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(12),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildGoalCard(SavingsGoal goal) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                goal.title,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '${(goal.progress * 100).round()}%',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.green700),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '${_formatMoney(goal.saved)} of ${_formatMoney(goal.target)}',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
              ),
          if (goal.dueDate != null) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              'Due: ${_formatDate(goal.dueDate!)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildTransactionCard(SavingsLog log) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  log.goalTitle,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  _formatDate(log.date),
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.Text(
            '+${_formatMoney(log.amount)}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.green800, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
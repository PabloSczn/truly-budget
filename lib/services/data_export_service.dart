import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/month_budget.dart';
import '../state/budget_store.dart';
import '../utils/format.dart';
import '../utils/year_month.dart';

enum ExportFormat { pdf, jpg, xlsx }

extension ExportFormatX on ExportFormat {
  String get label => switch (this) {
        ExportFormat.pdf => 'PDF',
        ExportFormat.jpg => 'JPG',
        ExportFormat.xlsx => 'XLSX',
      };

  String get fileExtension => switch (this) {
        ExportFormat.pdf => 'pdf',
        ExportFormat.jpg => 'jpg',
        ExportFormat.xlsx => 'xlsx',
      };

  IconData get icon => switch (this) {
        ExportFormat.pdf => Icons.picture_as_pdf_outlined,
        ExportFormat.jpg => Icons.image_outlined,
        ExportFormat.xlsx => Icons.table_chart_outlined,
      };
}

class GeneratedExportFile {
  final File file;
  final String title;
  final String shareText;

  const GeneratedExportFile({
    required this.file,
    required this.title,
    required this.shareText,
  });
}

class DataExportService {
  Future<GeneratedExportFile> exportMonth({
    required BudgetStore store,
    required String ymKey,
    required ExportFormat format,
  }) async {
    final budget = store.budgets[ymKey];
    if (budget == null) {
      throw Exception('Month budget not found.');
    }

    final report = _buildMonthReport(store, budget);
    final bytes = switch (format) {
      ExportFormat.pdf => await _buildMonthPdf(report),
      ExportFormat.jpg => await _buildMonthJpg(report),
      ExportFormat.xlsx => _buildMonthXlsx(report),
    };

    final file = await _writeFile(
      prefix: 'month_budget_${report.ymKey}',
      extension: format.fileExtension,
      bytes: bytes,
    );

    return GeneratedExportFile(
      file: file,
      title: 'Month budget ${report.title}',
      shareText: 'Month budget export for ${report.title}',
    );
  }

  Future<GeneratedExportFile> exportYear({
    required BudgetStore store,
    required int year,
    required ExportFormat format,
  }) async {
    final report = _buildYearReport(store, year);
    final hasAnyBudget = report.months.any((month) => month.isCreated);
    if (!hasAnyBudget) {
      throw Exception('There are no budgets for $year yet.');
    }

    final bytes = switch (format) {
      ExportFormat.pdf => await _buildYearPdf(report),
      ExportFormat.jpg => await _buildYearJpg(report),
      ExportFormat.xlsx => _buildYearXlsx(report),
    };

    final file = await _writeFile(
      prefix: 'year_balance_${report.year}',
      extension: format.fileExtension,
      bytes: bytes,
    );

    return GeneratedExportFile(
      file: file,
      title: 'Year balance ${report.year}',
      shareText: 'Year balance export for ${report.year}',
    );
  }

  Future<GeneratedExportFile> exportFullBackup(BudgetStore store) async {
    final archive = Archive();
    final now = DateTime.now();
    final stamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final backupJson = const JsonEncoder.withIndent('  ').convert(
      store.exportData(),
    );
    final readme = [
      'TrulyBudget backup',
      'Generated: $stamp',
      'Currency: ${store.currency.code} (${store.currency.symbol})',
      '',
      'This ZIP contains the raw app data in JSON format.',
    ].join('\n');

    final jsonBytes = utf8.encode(backupJson);
    final readmeBytes = utf8.encode(readme);
    archive
      ..addFile(
          ArchiveFile('trulybudget_backup.json', jsonBytes.length, jsonBytes))
      ..addFile(ArchiveFile('README.txt', readmeBytes.length, readmeBytes));

    final zipBytes = ZipEncoder().encode(archive);
    final file = await _writeFile(
      prefix: 'trulybudget_backup',
      extension: 'zip',
      bytes: Uint8List.fromList(zipBytes),
    );

    return GeneratedExportFile(
      file: file,
      title: 'Full app backup',
      shareText: 'TrulyBudget full backup',
    );
  }

  Future<File> _writeFile({
    required String prefix,
    required String extension,
    required Uint8List bytes,
  }) async {
    final directory = await _exportsDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/${prefix}_$stamp.$extension');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Directory> _exportsDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final directory = Directory('${baseDir.path}/exports');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  _MonthReport _buildMonthReport(BudgetStore store, MonthBudget budget) {
    final ym = YearMonth(budget.year, budget.month);
    final categories = budget.categories
        .map(
          (category) => _CategoryBalanceRow(
            label: _categoryLabel(category),
            allocated: category.allocated,
            spent: category.spent,
            balance: category.remaining,
          ),
        )
        .toList();

    final expenses = <_ExpenseRow>[];
    for (final category in budget.categories) {
      for (final expense in category.expenses) {
        expenses.add(
          _ExpenseRow(
            date: expense.date,
            category: _categoryLabel(category),
            note: _expenseNote(expense),
            amount: expense.amount,
          ),
        );
      }
    }

    final incomes = budget.incomes
        .map(
          (income) => _IncomeRow(
            date: income.date,
            source: _incomeLabel(income),
            amount: income.amount,
          ),
        )
        .toList();

    return _MonthReport(
      ymKey: ym.key,
      title: ym.label,
      currencyCode: store.currency.code,
      currencySymbol: store.currency.symbol,
      isCompleted: budget.isCompleted,
      totalIncome: budget.totalIncome,
      totalAllocated: budget.totalAllocated,
      totalExpenses: store.effectiveExpenseForBudget(budget),
      overallBalance: store.effectiveBalanceForBudget(budget),
      debt: store.debtForBudget(budget),
      carriedDebtAmount: budget.carriedDebtAmount,
      carriedDebtToLabel: budget.carriedDebtToKey == null
          ? null
          : YearMonth.labelFromKey(budget.carriedDebtToKey!),
      incomes: incomes,
      categories: categories,
      expenses: expenses,
    );
  }

  _YearReport _buildYearReport(BudgetStore store, int year) {
    final months = <_YearMonthRow>[];
    var totalIncome = 0.0;
    var totalExpenses = 0.0;

    for (var month = 1; month <= 12; month++) {
      final ymKey = '$year-${month.toString().padLeft(2, '0')}';
      final budget = store.budgets[ymKey];
      final income = budget?.totalIncome ?? 0.0;
      final expenses =
          budget == null ? 0.0 : store.effectiveExpenseForBudget(budget);
      final balance = income - expenses;

      totalIncome += income;
      totalExpenses += expenses;

      months.add(
        _YearMonthRow(
          label: YearMonth(year, month).label,
          status: budget == null
              ? 'Not created'
              : budget.isCompleted
                  ? 'Completed'
                  : 'Open',
          income: income,
          expenses: expenses,
          balance: balance,
          isCreated: budget != null,
        ),
      );
    }

    return _YearReport(
      year: year,
      currencyCode: store.currency.code,
      currencySymbol: store.currency.symbol,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      overallBalance: totalIncome - totalExpenses,
      months: months,
    );
  }

  Future<Uint8List> _buildMonthPdf(_MonthReport report) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          _pdfHeader(
            title: 'Month budget',
            subtitle: report.title,
            details: [
              'Currency: ${report.currencyCode} (${report.currencySymbol})',
              'Status: ${report.isCompleted ? 'Completed' : 'Open'}',
            ],
          ),
          pw.SizedBox(height: 12),
          _pdfSummaryTable(
            rows: [
              [
                'Total income',
                _money(report.totalIncome, report.currencySymbol)
              ],
              [
                'Allocated',
                _money(report.totalAllocated, report.currencySymbol),
              ],
              [
                'Effective expenses',
                _money(report.totalExpenses, report.currencySymbol),
              ],
              [
                'Overall balance',
                _money(report.overallBalance, report.currencySymbol),
              ],
              ['Debt', _money(report.debt, report.currencySymbol)],
              if (report.carriedDebtToLabel != null)
                [
                  'Debt carried forward',
                  '${_money(report.carriedDebtAmount, report.currencySymbol)} to ${report.carriedDebtToLabel}',
                ],
            ],
          ),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Income'),
          if (report.incomes.isEmpty)
            _pdfEmptyState('No income recorded.')
          else
            _pdfTable(
              headers: const ['Date', 'Source', 'Amount'],
              rows: report.incomes
                  .map(
                    (income) => [
                      _date(income.date),
                      _pdfText(income.source),
                      _money(income.amount, report.currencySymbol),
                    ],
                  )
                  .toList(),
            ),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Category balances'),
          if (report.categories.isEmpty)
            _pdfEmptyState('No categories recorded.')
          else
            _pdfTable(
              headers: const ['Category', 'Allocated', 'Spent', 'Balance'],
              rows: report.categories
                  .map(
                    (category) => [
                      _pdfText(category.label),
                      _money(category.allocated, report.currencySymbol),
                      _money(category.spent, report.currencySymbol),
                      _money(category.balance, report.currencySymbol),
                    ],
                  )
                  .toList(),
            ),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Expenses'),
          if (report.expenses.isEmpty)
            _pdfEmptyState('No expenses recorded.')
          else
            _pdfTable(
              headers: const ['Date', 'Category', 'Expense', 'Amount'],
              rows: report.expenses
                  .map(
                    (expense) => [
                      _date(expense.date),
                      _pdfText(expense.category),
                      _pdfText(expense.note),
                      _money(expense.amount, report.currencySymbol),
                    ],
                  )
                  .toList(),
            ),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  Future<Uint8List> _buildYearPdf(_YearReport report) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          _pdfHeader(
            title: 'Year balance',
            subtitle: report.year.toString(),
            details: [
              'Currency: ${report.currencyCode} (${report.currencySymbol})',
            ],
          ),
          pw.SizedBox(height: 12),
          _pdfSummaryTable(
            rows: [
              [
                'Total income',
                _money(report.totalIncome, report.currencySymbol)
              ],
              [
                'Total expenses',
                _money(report.totalExpenses, report.currencySymbol),
              ],
              [
                'Overall balance',
                _money(report.overallBalance, report.currencySymbol),
              ],
            ],
          ),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Monthly balances'),
          _pdfTable(
            headers: const ['Month', 'Status', 'Income', 'Expenses', 'Balance'],
            rows: report.months
                .map(
                  (month) => [
                    month.label,
                    month.status,
                    _money(month.income, report.currencySymbol),
                    _money(month.expenses, report.currencySymbol),
                    _money(month.balance, report.currencySymbol),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  Uint8List _buildMonthXlsx(_MonthReport report) {
    final rows = <List<_XlsxCell>>[
      [
        const _XlsxCell.text('Month budget', bold: true),
        _XlsxCell.text(report.title),
      ],
      [
        const _XlsxCell.text('Currency', bold: true),
        _XlsxCell.text('${report.currencyCode} (${report.currencySymbol})'),
      ],
      [
        const _XlsxCell.text('Status', bold: true),
        _XlsxCell.text(report.isCompleted ? 'Completed' : 'Open'),
      ],
      [
        const _XlsxCell.text('Total income', bold: true),
        _XlsxCell.number(report.totalIncome),
      ],
      [
        const _XlsxCell.text('Allocated', bold: true),
        _XlsxCell.number(report.totalAllocated),
      ],
      [
        const _XlsxCell.text('Effective expenses', bold: true),
        _XlsxCell.number(report.totalExpenses),
      ],
      [
        const _XlsxCell.text('Overall balance', bold: true),
        _XlsxCell.number(report.overallBalance),
      ],
      [
        const _XlsxCell.text('Debt', bold: true),
        _XlsxCell.number(report.debt),
      ],
      [],
      [const _XlsxCell.text('Income', bold: true)],
      [
        const _XlsxCell.text('Date', bold: true),
        const _XlsxCell.text('Source', bold: true),
        const _XlsxCell.text('Amount', bold: true),
      ],
      ...report.incomes.map(
        (income) => [
          _XlsxCell.text(_date(income.date)),
          _XlsxCell.text(income.source),
          _XlsxCell.number(income.amount),
        ],
      ),
      [],
      [const _XlsxCell.text('Category balances', bold: true)],
      [
        const _XlsxCell.text('Category', bold: true),
        const _XlsxCell.text('Allocated', bold: true),
        const _XlsxCell.text('Spent', bold: true),
        const _XlsxCell.text('Balance', bold: true),
      ],
      ...report.categories.map(
        (category) => [
          _XlsxCell.text(category.label),
          _XlsxCell.number(category.allocated),
          _XlsxCell.number(category.spent),
          _XlsxCell.number(category.balance),
        ],
      ),
      [],
      [const _XlsxCell.text('Expenses', bold: true)],
      [
        const _XlsxCell.text('Date', bold: true),
        const _XlsxCell.text('Category', bold: true),
        const _XlsxCell.text('Expense', bold: true),
        const _XlsxCell.text('Amount', bold: true),
      ],
      ...report.expenses.map(
        (expense) => [
          _XlsxCell.text(_date(expense.date)),
          _XlsxCell.text(expense.category),
          _XlsxCell.text(expense.note),
          _XlsxCell.number(expense.amount),
        ],
      ),
    ];

    return _buildWorkbook(
      sheetName: report.title,
      rows: rows,
      creator: 'TrulyBudget',
      title: 'Month budget ${report.title}',
    );
  }

  Uint8List _buildYearXlsx(_YearReport report) {
    final rows = <List<_XlsxCell>>[
      [
        const _XlsxCell.text('Year balance', bold: true),
        _XlsxCell.text(report.year.toString()),
      ],
      [
        const _XlsxCell.text('Currency', bold: true),
        _XlsxCell.text('${report.currencyCode} (${report.currencySymbol})'),
      ],
      [
        const _XlsxCell.text('Total income', bold: true),
        _XlsxCell.number(report.totalIncome),
      ],
      [
        const _XlsxCell.text('Total expenses', bold: true),
        _XlsxCell.number(report.totalExpenses),
      ],
      [
        const _XlsxCell.text('Overall balance', bold: true),
        _XlsxCell.number(report.overallBalance),
      ],
      [],
      [const _XlsxCell.text('Monthly balances', bold: true)],
      [
        const _XlsxCell.text('Month', bold: true),
        const _XlsxCell.text('Status', bold: true),
        const _XlsxCell.text('Income', bold: true),
        const _XlsxCell.text('Expenses', bold: true),
        const _XlsxCell.text('Balance', bold: true),
      ],
      ...report.months.map(
        (month) => [
          _XlsxCell.text(month.label),
          _XlsxCell.text(month.status),
          _XlsxCell.number(month.income),
          _XlsxCell.number(month.expenses),
          _XlsxCell.number(month.balance),
        ],
      ),
    ];

    return _buildWorkbook(
      sheetName: report.year.toString(),
      rows: rows,
      creator: 'TrulyBudget',
      title: 'Year balance ${report.year}',
    );
  }

  Uint8List _buildWorkbook({
    required String sheetName,
    required List<List<_XlsxCell>> rows,
    required String creator,
    required String title,
  }) {
    final safeSheetName = _safeSheetName(sheetName);
    final now = DateTime.now().toUtc().toIso8601String();
    final worksheet = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write(
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
      )
      ..write('<sheetViews><sheetView workbookViewId="0"/></sheetViews>')
      ..write('<sheetFormatPr defaultRowHeight="15"/>')
      ..write('<cols>');

    for (var column = 0; column < 8; column++) {
      worksheet.write(
        '<col min="${column + 1}" max="${column + 1}" width="${column == 0 ? 24 : 18}" customWidth="1"/>',
      );
    }

    worksheet
      ..write('</cols>')
      ..write('<sheetData>');

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final rowNumber = rowIndex + 1;
      worksheet.write('<row r="$rowNumber">');
      for (var columnIndex = 0; columnIndex < row.length; columnIndex++) {
        final cell = row[columnIndex];
        final ref = '${_columnName(columnIndex)}$rowNumber';
        worksheet.write(cell.toXml(ref));
      }
      worksheet.write('</row>');
    }

    worksheet.write('</sheetData></worksheet>');

    const contentTypes = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
''';

    const rootRels = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
''';

    final workbook = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="${_xml(safeSheetName)}" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>
''';

    const workbookRels = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
''';

    const styles = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="2">
    <font><sz val="11"/><name val="Calibri"/></font>
    <font><b/><sz val="11"/><name val="Calibri"/></font>
  </fonts>
  <fills count="2">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
  </fills>
  <borders count="1">
    <border><left/><right/><top/><bottom/><diagonal/></border>
  </borders>
  <cellStyleXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  </cellStyleXfs>
  <cellXfs count="4">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>
    <xf numFmtId="4" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
    <xf numFmtId="4" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1" applyNumberFormat="1"/>
  </cellXfs>
  <cellStyles count="1">
    <cellStyle name="Normal" xfId="0" builtinId="0"/>
  </cellStyles>
</styleSheet>
''';

    const app = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>TrulyBudget</Application>
</Properties>
''';

    final core = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:creator>${_xml(creator)}</dc:creator>
  <cp:lastModifiedBy>${_xml(creator)}</cp:lastModifiedBy>
  <dc:title>${_xml(title)}</dc:title>
  <dcterms:created xsi:type="dcterms:W3CDTF">$now</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$now</dcterms:modified>
</cp:coreProperties>
''';

    final archive = Archive()
      ..addFile(
        ArchiveFile(
          '[Content_Types].xml',
          utf8.encode(contentTypes).length,
          utf8.encode(contentTypes),
        ),
      )
      ..addFile(
        ArchiveFile(
          '_rels/.rels',
          utf8.encode(rootRels).length,
          utf8.encode(rootRels),
        ),
      )
      ..addFile(
        ArchiveFile(
          'xl/workbook.xml',
          utf8.encode(workbook).length,
          utf8.encode(workbook),
        ),
      )
      ..addFile(
        ArchiveFile(
          'xl/_rels/workbook.xml.rels',
          utf8.encode(workbookRels).length,
          utf8.encode(workbookRels),
        ),
      )
      ..addFile(
        ArchiveFile(
          'xl/styles.xml',
          utf8.encode(styles).length,
          utf8.encode(styles),
        ),
      )
      ..addFile(
        ArchiveFile(
          'xl/worksheets/sheet1.xml',
          utf8.encode(worksheet.toString()).length,
          utf8.encode(worksheet.toString()),
        ),
      )
      ..addFile(
        ArchiveFile(
            'docProps/app.xml', utf8.encode(app).length, utf8.encode(app)),
      )
      ..addFile(
        ArchiveFile(
          'docProps/core.xml',
          utf8.encode(core).length,
          utf8.encode(core),
        ),
      );

    final bytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List> _buildMonthJpg(_MonthReport report) async {
    const width = 1440.0;
    final png = await _drawSummaryCanvas(
      width: width,
      title: 'Month budget',
      subtitle: report.title,
      summaryCards: [
        _SummaryCardData(
          label: 'Income',
          value: _money(report.totalIncome, report.currencySymbol),
          color: Colors.teal,
        ),
        _SummaryCardData(
          label: 'Expenses',
          value: _money(report.totalExpenses, report.currencySymbol),
          color: Colors.orange,
        ),
        _SummaryCardData(
          label: 'Overall balance',
          value: _money(report.overallBalance, report.currencySymbol),
          color: report.overallBalance >= 0 ? Colors.green : Colors.red,
        ),
      ],
      tableHeaders: const ['Category', 'Balance'],
      tableRows: report.categories
          .map(
            (category) => [
              category.label,
              _money(category.balance, report.currencySymbol),
            ],
          )
          .toList(),
      highlightNegativeColumn: 1,
    );
    return _pngToJpg(png);
  }

  Future<Uint8List> _buildYearJpg(_YearReport report) async {
    const width = 1440.0;
    final png = await _drawSummaryCanvas(
      width: width,
      title: 'Year balance',
      subtitle: report.year.toString(),
      summaryCards: [
        _SummaryCardData(
          label: 'Income',
          value: _money(report.totalIncome, report.currencySymbol),
          color: Colors.teal,
        ),
        _SummaryCardData(
          label: 'Expenses',
          value: _money(report.totalExpenses, report.currencySymbol),
          color: Colors.orange,
        ),
        _SummaryCardData(
          label: 'Year balance',
          value: _money(report.overallBalance, report.currencySymbol),
          color: report.overallBalance >= 0 ? Colors.green : Colors.red,
        ),
      ],
      tableHeaders: const ['Month', 'Balance'],
      tableRows: report.months
          .map(
            (month) => [
              month.label,
              _money(month.balance, report.currencySymbol),
            ],
          )
          .toList(),
      highlightNegativeColumn: 1,
    );
    return _pngToJpg(png);
  }

  Future<Uint8List> _drawSummaryCanvas({
    required double width,
    required String title,
    required String subtitle,
    required List<_SummaryCardData> summaryCards,
    required List<String> tableHeaders,
    required List<List<String>> tableRows,
    required int highlightNegativeColumn,
  }) async {
    const cardTop = 208.0;
    const tableTop = cardTop + 170.0;
    const rowStride = 62.0;
    const tableTopContent = 146.0;
    const tableBottomPadding = 40.0;
    const imageBottomPadding = 48.0;
    final tableRowsHeight =
        tableRows.isEmpty ? 86.0 : tableRows.length * rowStride;
    final tableHeight = tableTopContent + tableRowsHeight + tableBottomPadding;
    final height = tableTop + tableHeight + imageBottomPadding;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final pageRect = Rect.fromLTWH(0, 0, width, height);

    canvas.drawRect(
      pageRect,
      Paint()..color = const Color(0xFFF7FBFA),
    );

    final gradientRect = Rect.fromLTWH(0, 0, width, 210);
    canvas.drawRect(
      gradientRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(gradientRect),
    );

    _drawText(
      canvas,
      title,
      const Offset(72, 56),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 38,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: width - 144,
    );
    _drawText(
      canvas,
      subtitle,
      const Offset(72, 106),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w500,
      ),
      maxWidth: width - 144,
    );
    _drawText(
      canvas,
      'Generated ${DateFormat('d MMM yyyy, HH:mm').format(DateTime.now())}',
      const Offset(72, 146),
      style: const TextStyle(
        color: Color(0xFFE6FFFB),
        fontSize: 18,
      ),
      maxWidth: width - 144,
    );

    const cardLeft = 72.0;
    const cardGap = 22.0;
    final cardWidth = (width - cardLeft * 2 - cardGap * 2) / 3;
    for (var index = 0; index < summaryCards.length; index++) {
      final card = summaryCards[index];
      final left = cardLeft + index * (cardWidth + cardGap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, cardTop, cardWidth, 132),
        const Radius.circular(28),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = card.color.withValues(alpha: 0.22),
      );
      canvas.drawCircle(
        Offset(left + 32, cardTop + 34),
        8,
        Paint()..color = card.color,
      );
      _drawText(
        canvas,
        card.label,
        Offset(left + 52, cardTop + 18),
        style: TextStyle(
          color: Colors.blueGrey.shade700,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        maxWidth: cardWidth - 70,
      );
      _drawText(
        canvas,
        card.value,
        Offset(left + 24, cardTop + 54),
        style: TextStyle(
          color: card.color,
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
        maxWidth: cardWidth - 48,
      );
    }

    final tableRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(72, tableTop, width - 144, height - tableTop - 48),
      const Radius.circular(28),
    );
    canvas.drawRRect(tableRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      tableRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFD2E8E4),
    );

    _drawText(
      canvas,
      'Balances',
      Offset(tableRect.left + 28, tableRect.top + 24),
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: tableRect.width - 56,
    );

    final headerTop = tableRect.top + 76;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          tableRect.left + 18,
          headerTop,
          tableRect.width - 36,
          54,
        ),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFFE7F7F4),
    );

    final firstColumnWidth = (tableRect.width - 36) * 0.65;
    final secondColumnLeft = tableRect.left + 18 + firstColumnWidth;
    _drawText(
      canvas,
      tableHeaders.first,
      Offset(tableRect.left + 36, headerTop + 15),
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: firstColumnWidth - 30,
    );
    _drawText(
      canvas,
      tableHeaders.last,
      Offset(secondColumnLeft + 18, headerTop + 15),
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: tableRect.width - firstColumnWidth - 72,
    );

    final dividerPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    var currentTop = headerTop + 70;
    if (tableRows.isEmpty) {
      _drawText(
        canvas,
        'No balances available yet.',
        Offset(tableRect.left + 36, currentTop + 8),
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        maxWidth: firstColumnWidth - 30,
        maxLines: 1,
      );
    } else {
      for (var index = 0; index < tableRows.length; index++) {
        final row = tableRows[index];
        if (index.isEven) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                tableRect.left + 18,
                currentTop - 6,
                tableRect.width - 36,
                54,
              ),
              const Radius.circular(14),
            ),
            Paint()..color = const Color(0xFFF8FCFB),
          );
        }

        _drawText(
          canvas,
          row.first,
          Offset(tableRect.left + 36, currentTop + 8),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          maxWidth: firstColumnWidth - 30,
          maxLines: 1,
        );

        final valueColor = row[highlightNegativeColumn].contains('-')
            ? Colors.red
            : Colors.green;
        _drawText(
          canvas,
          row[highlightNegativeColumn],
          Offset(secondColumnLeft + 18, currentTop + 8),
          style: TextStyle(
            color: valueColor.shade700,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          maxWidth: tableRect.width - firstColumnWidth - 72,
          maxLines: 1,
        );

        if (index != tableRows.length - 1) {
          canvas.drawLine(
            Offset(tableRect.left + 28, currentTop + 55),
            Offset(tableRect.right - 28, currentTop + 55),
            dividerPaint,
          );
        }
        currentTop += rowStride;
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.ceil(), height.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Could not create the image export.');
    }
    return byteData.buffer.asUint8List();
  }

  Uint8List _pngToJpg(Uint8List pngBytes) {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) {
      throw Exception('Could not convert the image export.');
    }
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
  }

  Size _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required TextStyle style,
    required double maxWidth,
    int? maxLines,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '...',
      textAlign: textAlign,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
    return painter.size;
  }

  pw.Widget _pdfHeader({
    required String title,
    required String subtitle,
    required List<String> details,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(16),
        color: PdfColor.fromHex('#E7F7F4'),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _pdfText(title),
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _pdfText(subtitle),
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          for (final detail in details)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(_pdfText(detail)),
            ),
        ],
      ),
    );
  }

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Text(
      _pdfText(title),
      style: pw.TextStyle(
        fontSize: 15,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _pdfEmptyState(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Text(_pdfText(text)),
    );
  }

  pw.Widget _pdfSummaryTable({required List<List<String>> rows}) {
    return _pdfTable(headers: const ['Item', 'Value'], rows: rows);
  }

  pw.Widget _pdfTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers.map(_pdfText).toList(),
      data: rows
          .map((row) => row.map(_pdfText).toList(growable: false))
          .toList(growable: false),
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#D5F0EA'),
      ),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      cellAlignments: {
        for (var column = 0; column < headers.length; column++)
          column:
              column == 0 ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
      },
    );
  }

  String _money(double value, String currencySymbol) {
    return Format.money(value, symbol: currencySymbol);
  }

  String _date(DateTime value) => DateFormat('dd MMM yyyy').format(value);

  static String _categoryLabel(Category category) {
    final name = category.name.trim();
    if (name.isEmpty) return category.emoji;
    return '${category.emoji} $name'.trim();
  }

  static String _incomeLabel(Income income) =>
      income.source.trim().isEmpty ? 'Income' : income.source.trim();

  static String _expenseNote(Expense expense) =>
      expense.note.trim().isEmpty ? 'Expense' : expense.note.trim();

  String _pdfText(String value) {
    final cleaned = value
        .replaceAll(
          RegExp(
            r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
            unicode: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? '-' : cleaned;
  }

  String _safeSheetName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[\[\]\*:/\\?]'), ' ').trim();
    if (sanitized.isEmpty) return 'Sheet1';
    if (sanitized.length <= 31) return sanitized;
    return sanitized.substring(0, 31);
  }

  String _columnName(int index) {
    var value = index;
    var name = '';
    do {
      name = String.fromCharCode(65 + value % 26) + name;
      value = (value ~/ 26) - 1;
    } while (value >= 0);
    return name;
  }

  static String _xml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

class _MonthReport {
  final String ymKey;
  final String title;
  final String currencyCode;
  final String currencySymbol;
  final bool isCompleted;
  final double totalIncome;
  final double totalAllocated;
  final double totalExpenses;
  final double overallBalance;
  final double debt;
  final double carriedDebtAmount;
  final String? carriedDebtToLabel;
  final List<_IncomeRow> incomes;
  final List<_CategoryBalanceRow> categories;
  final List<_ExpenseRow> expenses;

  const _MonthReport({
    required this.ymKey,
    required this.title,
    required this.currencyCode,
    required this.currencySymbol,
    required this.isCompleted,
    required this.totalIncome,
    required this.totalAllocated,
    required this.totalExpenses,
    required this.overallBalance,
    required this.debt,
    required this.carriedDebtAmount,
    required this.carriedDebtToLabel,
    required this.incomes,
    required this.categories,
    required this.expenses,
  });
}

class _YearReport {
  final int year;
  final String currencyCode;
  final String currencySymbol;
  final double totalIncome;
  final double totalExpenses;
  final double overallBalance;
  final List<_YearMonthRow> months;

  const _YearReport({
    required this.year,
    required this.currencyCode,
    required this.currencySymbol,
    required this.totalIncome,
    required this.totalExpenses,
    required this.overallBalance,
    required this.months,
  });
}

class _IncomeRow {
  final DateTime date;
  final String source;
  final double amount;

  const _IncomeRow({
    required this.date,
    required this.source,
    required this.amount,
  });
}

class _ExpenseRow {
  final DateTime date;
  final String category;
  final String note;
  final double amount;

  const _ExpenseRow({
    required this.date,
    required this.category,
    required this.note,
    required this.amount,
  });
}

class _CategoryBalanceRow {
  final String label;
  final double allocated;
  final double spent;
  final double balance;

  const _CategoryBalanceRow({
    required this.label,
    required this.allocated,
    required this.spent,
    required this.balance,
  });
}

class _YearMonthRow {
  final String label;
  final String status;
  final double income;
  final double expenses;
  final double balance;
  final bool isCreated;

  const _YearMonthRow({
    required this.label,
    required this.status,
    required this.income,
    required this.expenses,
    required this.balance,
    required this.isCreated,
  });
}

class _SummaryCardData {
  final String label;
  final String value;
  final MaterialColor color;

  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _XlsxCell {
  final String? textValue;
  final double? numberValue;
  final bool bold;

  const _XlsxCell._({
    required this.textValue,
    required this.numberValue,
    required this.bold,
  });

  const _XlsxCell.text(String value, {bool bold = false})
      : this._(textValue: value, numberValue: null, bold: bold);

  const _XlsxCell.number(double value, {bool bold = false})
      : this._(textValue: null, numberValue: value, bold: bold);

  String toXml(String reference) {
    if (textValue == null && numberValue == null) {
      return '';
    }

    final styleId = numberValue == null ? (bold ? 1 : 0) : (bold ? 3 : 2);

    if (numberValue != null) {
      return '<c r="$reference" s="$styleId"><v>$numberValue</v></c>';
    }

    return '<c r="$reference" t="inlineStr" s="$styleId"><is><t xml:space="preserve">${DataExportService._xml(textValue!)}</t></is></c>';
  }
}

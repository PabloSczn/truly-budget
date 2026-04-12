import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/data_export_service.dart';
import '../state/budget_store.dart';
import '../utils/year_month.dart';
import '../widgets/app_menu_drawer.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final DataExportService _exportService = DataExportService();
  String? _selectedMonthKey;
  int? _selectedYear;
  bool _isBusy = false;
  String? _busyLabel;

  String? _resolvedMonthKey(BudgetStore store) {
    final monthKeys = store.monthKeysDesc;
    if (monthKeys.isEmpty) return null;
    if (_selectedMonthKey != null && monthKeys.contains(_selectedMonthKey)) {
      return _selectedMonthKey;
    }
    if (store.selectedYMKey != null &&
        monthKeys.contains(store.selectedYMKey)) {
      return store.selectedYMKey;
    }
    return monthKeys.first;
  }

  int? _resolvedYear(BudgetStore store) {
    final years = _availableYears(store);
    if (years.isEmpty) return null;
    if (_selectedYear != null && years.contains(_selectedYear)) {
      return _selectedYear;
    }
    if (years.contains(DateTime.now().year)) {
      return DateTime.now().year;
    }
    return years.first;
  }

  List<int> _availableYears(BudgetStore store) {
    final years = store.monthKeysDesc
        .map((key) => int.parse(key.split('-').first))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  Future<void> _runBusyTask(
    String label,
    Future<void> Function() action,
  ) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _busyLabel = label;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_messageFromError(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _busyLabel = null;
        });
      }
    }
  }

  Future<void> _shareGeneratedFile(GeneratedExportFile exported) async {
    final renderObject = context.findRenderObject();
    final renderBox = renderObject is RenderBox ? renderObject : null;
    final origin = renderBox == null
        ? null
        : renderBox.localToGlobal(Offset.zero) & renderBox.size;

    try {
      await Share.shareXFiles(
        [XFile(exported.file.path)],
        text: exported.shareText,
        subject: exported.title,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      // The file is still saved locally even if the share sheet cannot open.
    }

    if (!mounted) return;
    final fileName = exported.file.uri.pathSegments.last;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$fileName created in the app exports folder.')),
    );
  }

  String _messageFromError(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw.isEmpty ? 'Something went wrong.' : raw;
  }

  Future<void> _exportMonth(ExportFormat format) async {
    final store = context.read<BudgetStore>();
    final monthKey = _resolvedMonthKey(store);
    if (monthKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a month budget first.')),
      );
      return;
    }

    await _runBusyTask('Creating ${format.label} month export...', () async {
      final exported = await _exportService.exportMonth(
        store: store,
        ymKey: monthKey,
        format: format,
      );
      if (!mounted) return;
      await _shareGeneratedFile(exported);
    });
  }

  Future<void> _exportYear(ExportFormat format) async {
    final store = context.read<BudgetStore>();
    final year = _resolvedYear(store);
    if (year == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a budget first.')),
      );
      return;
    }

    await _runBusyTask('Creating ${format.label} year export...', () async {
      final exported = await _exportService.exportYear(
        store: store,
        year: year,
        format: format,
      );
      if (!mounted) return;
      await _shareGeneratedFile(exported);
    });
  }

  Future<void> _exportBackup() async {
    final store = context.read<BudgetStore>();
    await _runBusyTask('Preparing the full backup...', () async {
      final exported = await _exportService.exportFullBackup(store);
      if (!mounted) return;
      await _shareGeneratedFile(exported);
    });
  }

  Future<bool> _confirmImportOverwrite(List<String> monthKeys) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _ImportOverwriteDialog(monthKeys: monthKeys),
    );
    return confirm ?? false;
  }

  String _importSuccessMessage(BudgetImportPreview preview) {
    final importedCount = preview.importedMonthCount;
    final overwrittenCount = preview.overwrittenMonthKeys.length;

    if (importedCount == 0) {
      return 'JSON backup imported. No month budgets were added.';
    }

    final importedLabel =
        '$importedCount month budget${importedCount == 1 ? '' : 's'}';
    if (overwrittenCount == 0) {
      return 'Imported $importedLabel from JSON.';
    }

    final overwrittenLabel =
        '$overwrittenCount existing month${overwrittenCount == 1 ? '' : 's'}';
    return 'Imported $importedLabel and replaced $overwrittenLabel.';
  }

  Future<void> _importJsonBackup() async {
    if (_isBusy) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        allowMultiple: false,
        withData: true,
      );
      if (!mounted || result == null || result.xFiles.isEmpty) return;

      final pickedFile = result.xFiles.single;
      final rawJson = await pickedFile.readAsString();
      if (!mounted) return;

      final store = context.read<BudgetStore>();
      final preview = store.prepareImportJson(rawJson);

      if (preview.overwrittenMonthKeys.isNotEmpty) {
        final confirmed =
            await _confirmImportOverwrite(preview.overwrittenMonthKeys);
        if (!mounted || !confirmed) return;
      }

      await _runBusyTask('Importing ${pickedFile.name}...', () async {
        final messenger = ScaffoldMessenger.of(context);
        await store.importPreparedData(preview);
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(_importSuccessMessage(preview))),
        );
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_messageFromError(error))),
        );
      }
    }
  }

  Future<bool> _confirmReset(BudgetStore store) async {
    final monthCount = store.budgets.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _ResetConfirmationDialog(monthCount: monthCount),
    );
    return confirm ?? false;
  }

  Future<void> _resetAllData() async {
    final store = context.read<BudgetStore>();
    final confirmed = await _confirmReset(store);
    if (!mounted || !confirmed) return;

    await _runBusyTask('Removing all app data...', () async {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      await store.resetAllData();
      messenger.showSnackBar(
        const SnackBar(content: Text('All app data has been removed.')),
      );
      if (!mounted) return;
      navigator.popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monthKeys = store.monthKeysDesc;
    final selectedMonthKey = _resolvedMonthKey(store);
    final years = _availableYears(store);
    final selectedYear = _resolvedYear(store);
    const dangerColor = Colors.red;
    final dangerBackground = Color.alphaBlend(
      dangerColor.withValues(alpha: 0.1),
      colorScheme.surface,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Data & Exports')),
      drawer: const AppMenuDrawer(),
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            Card(
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage your data',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create shareable exports for a month or a whole year, download a full backup of your raw data, import a JSON backup, or reset the app completely.',
                    ),
                    if (_isBusy) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(_busyLabel ?? 'Working...'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Month budget export',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PDF and XLSX include the full month budget with income, category balances, and expenses. JPG keeps a compact summary with each category balance and the overall month balance.',
                    ),
                    const SizedBox(height: 16),
                    if (monthKeys.isEmpty)
                      const Text('Create a month budget to enable this export.')
                    else ...[
                      DropdownButtonFormField<String>(
                        key: ValueKey(selectedMonthKey),
                        initialValue: selectedMonthKey,
                        decoration: const InputDecoration(
                          labelText: 'Month',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final key in monthKeys)
                            DropdownMenuItem(
                              value: key,
                              child: Text(YearMonth.labelFromKey(key)),
                            ),
                        ],
                        onChanged: _isBusy
                            ? null
                            : (value) =>
                                setState(() => _selectedMonthKey = value),
                      ),
                      const SizedBox(height: 16),
                      _ExportButtons(
                        enabled: !_isBusy,
                        onPressed: _exportMonth,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Year balance export',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PDF and XLSX include a year summary with every month. JPG keeps only the balance of each month and the overall year balance.',
                    ),
                    const SizedBox(height: 16),
                    if (years.isEmpty)
                      const Text(
                          'Create a budget first to enable year exports.')
                    else ...[
                      DropdownButtonFormField<int>(
                        key: ValueKey(selectedYear),
                        initialValue: selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final year in years)
                            DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            ),
                        ],
                        onChanged: _isBusy
                            ? null
                            : (value) => setState(() => _selectedYear = value),
                      ),
                      const SizedBox(height: 16),
                      _ExportButtons(
                        enabled: !_isBusy,
                        onPressed: _exportYear,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full app backup',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Creates a ZIP file with the raw JSON backup of everything stored in the app.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isBusy ? null : _exportBackup,
                      icon: const Icon(Icons.archive_outlined),
                      label: const Text('Create ZIP backup'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import data',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Imports a raw TrulyBudget JSON and merges its months into the app. If the file would replace any month that already has data, you will be asked to confirm before importing.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isBusy ? null : _importJsonBackup,
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('Import data'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: dangerBackground,
                border: Border.all(
                  color: dangerColor.withValues(alpha: 0.18),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 560;
                  final resetButtonStyle = FilledButton.styleFrom(
                    backgroundColor: dangerColor,
                    foregroundColor: Colors.white,
                  );

                  Widget buildResetButton({required bool expand}) {
                    final button = FilledButton.icon(
                      style: resetButtonStyle,
                      onPressed: _isBusy ? null : _resetAllData,
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: const Text('Delete all app data'),
                    );
                    if (!expand) return button;
                    return SizedBox(width: double.infinity, child: button);
                  }

                  final warningBadge = Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: dangerColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: dangerColor,
                      size: 22,
                    ),
                  );

                  final warningText = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset app data',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This removes every month budget, income entry, category, expense, and saved preference so the app goes back to a clean start.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            warningBadge,
                            const SizedBox(width: 12),
                            Expanded(child: warningText),
                          ],
                        ),
                        const SizedBox(height: 16),
                        buildResetButton(expand: true),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      warningBadge,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            warningText,
                            const SizedBox(height: 16),
                            buildResetButton(expand: false),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportButtons extends StatelessWidget {
  final bool enabled;
  final Future<void> Function(ExportFormat format) onPressed;

  const _ExportButtons({
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final format in ExportFormat.values)
          FilledButton.tonalIcon(
            onPressed: enabled ? () => onPressed(format) : null,
            icon: Icon(format.icon),
            label: Text(format.label),
          ),
      ],
    );
  }
}

class _ImportOverwriteDialog extends StatelessWidget {
  final List<String> monthKeys;

  const _ImportOverwriteDialog({required this.monthKeys});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sortedMonthKeys = monthKeys.toList()..sort((a, b) => b.compareTo(a));
    final monthCount = sortedMonthKeys.length;

    return AlertDialog(
      scrollable: true,
      title: const Text('Replace existing month data?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Importing this JSON will override the current data for $monthCount month budget${monthCount == 1 ? '' : 's'}.',
          ),
          const SizedBox(height: 16),
          Text(
            'Affected months',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0;
                    index < sortedMonthKeys.length;
                    index++) ...[
                  if (index > 0)
                    Divider(
                      height: 16,
                      color: colorScheme.outlineVariant,
                    ),
                  Text(YearMonth.labelFromKey(sortedMonthKeys[index])),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This cannot be undone.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Replace data'),
        ),
      ],
    );
  }
}

class _ResetConfirmationDialog extends StatefulWidget {
  final int monthCount;

  const _ResetConfirmationDialog({required this.monthCount});

  @override
  State<_ResetConfirmationDialog> createState() =>
      _ResetConfirmationDialogState();
}

class _ResetConfirmationDialogState extends State<_ResetConfirmationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final canDelete = _controller.text.trim() == 'RESET';
    if (canDelete == _canDelete) return;
    setState(() => _canDelete = canDelete);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _close(bool confirmed) {
    Navigator.of(context).pop(confirmed);
  }

  @override
  Widget build(BuildContext context) {
    final monthCount = widget.monthCount;

    return AlertDialog(
      scrollable: true,
      title: const Text('Reset all app data?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will permanently remove $monthCount month budget${monthCount == 1 ? '' : 's'}, your currency selection and all your data',
          ),
          const SizedBox(height: 16),
          const Text(
            'Type RESET to confirm.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (_canDelete) _close(true);
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'RESET',
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _close(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _canDelete ? () => _close(true) : null,
          child: const Text('Delete everything'),
        ),
      ],
    );
  }
}

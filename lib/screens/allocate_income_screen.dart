import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/budget_store.dart';
import '../widgets/add_category_dialog.dart';
import '../utils/format.dart';

class AllocateIncomeScreen extends StatefulWidget {
  const AllocateIncomeScreen({super.key});

  @override
  State<AllocateIncomeScreen> createState() => _AllocateIncomeScreenState();
}

class _AllocateIncomeScreenState extends State<AllocateIncomeScreen> {
  bool usePercent = false;

  final Map<String, TextEditingController> ctrls = {};
  final Map<String, FocusNode> foci = {};

  /// Source of truth for this screen (ALWAYS amounts in currency)
  final Map<String, double> draftAmounts = {};

  double _totalIncome = 0.0;

  @override
  void dispose() {
    for (final c in ctrls.values) {
      c.dispose();
    }
    for (final f in foci.values) {
      f.dispose();
    }
    super.dispose();
  }

  double _parseNum(String s) {
    final t = s.trim().replaceAll(',', '.');
    return double.tryParse(t) ?? 0.0;
  }

  bool _isDisplayedZero(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    final v = _parseNum(t);
    return v.abs() < 1e-9;
  }

  String _fmtAmount(double v) => v.toStringAsFixed(2);

  String _fmtPercent(double v) {
    // Use 2 decimals to avoid misleading rounding
    var s = v.toStringAsFixed(2);
    while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  double _percentOfIncome(double amount, double totalIncome) {
    if (totalIncome <= 0) return 0.0;
    return (amount / totalIncome) * 100.0;
  }

  TextEditingController _ensureController(String id, String initialText) {
    return ctrls.putIfAbsent(
        id, () => TextEditingController(text: initialText));
  }

  FocusNode _ensureFocusNode(String id) {
    return foci.putIfAbsent(id, () {
      final node = FocusNode();
      node.addListener(() {
        if (!node.hasFocus) return;

        final ctrl = ctrls[id];
        if (ctrl == null) return;

        final text = ctrl.text;

        // If it's zero (e.g. "0.00" or "0"), clear it for fast entry
        if (_isDisplayedZero(text)) {
          ctrl.clear();
          return;
        }

        // Otherwise select all for easy overwrite (e.g. "100.00")
        ctrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: ctrl.text.length,
        );
      });
      return node;
    });
  }

  void _ensureDraftForCategory(String id, double currentAllocated) {
    draftAmounts.putIfAbsent(id, () => currentAllocated);
  }

  String _displayTextFor(String id) {
    final amount = draftAmounts[id] ?? 0.0;
    return usePercent
        ? _fmtPercent(_percentOfIncome(amount, _totalIncome))
        : _fmtAmount(amount);
  }

  void _onChangedFor(String id, String rawText) {
    final v = _parseNum(rawText);

    if (usePercent) {
      // user typed a percent, store as amount
      final pct = (v.isFinite && v >= 0) ? v : 0.0;
      final amount = _totalIncome <= 0 ? 0.0 : _totalIncome * (pct / 100.0);
      draftAmounts[id] = amount.isFinite && amount >= 0 ? amount : 0.0;
    } else {
      // user typed an amount, store as amount
      final amount = (v.isFinite && v >= 0) ? v : 0.0;
      draftAmounts[id] = amount;
    }

    setState(() {});
  }

  void _toggleMode(bool toPercent) {
    setState(() {
      usePercent = toPercent;

      // Update the visible text based on the draftAmounts (source of truth)
      for (final entry in ctrls.entries) {
        final id = entry.key;
        final ctrl = entry.value;
        final text = _displayTextFor(id);
        ctrl.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final b = store.currentBudget!;
    _totalIncome = b.totalIncome;

    for (final c in b.categories) {
      _ensureDraftForCategory(c.id, c.allocated);

      final initialText = _displayTextFor(c.id);
      _ensureController(c.id, initialText);
      _ensureFocusNode(c.id);
    }

    final draftAllocated = b.categories.fold<double>(
      0.0,
      (sum, c) => sum + (draftAmounts[c.id] ?? 0.0),
    );

    final draftUnallocated = _totalIncome - draftAllocated;

    final canSave = (_totalIncome > 0) || (b.totalAllocated > 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Allocate income')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allocate your remaining income to categories. You can enter allocations as ${usePercent ? 'percentages (%)' : 'actual amounts'}.',
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Use %'),
                        Switch(
                          value: usePercent,
                          onChanged: _toggleMode,
                        ),
                        const Spacer(),
                        Text(
                          'Income: ${Format.money(_totalIncome, symbol: store.currency.symbol)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Allocated: ${Format.money(draftAllocated, symbol: store.currency.symbol)}',
                        ),
                      ],
                    ),
                    if (draftUnallocated < -1e-6) ...[
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_outlined, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You are allocating more than your total income.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  for (final c in b.categories)
                    ListTile(
                      title: Text('${c.emoji}  ${c.name}'),
                      trailing: SizedBox(
                        width: 130,
                        child: TextField(
                          controller: ctrls[c.id],
                          focusNode: foci[c.id],
                          textAlign: TextAlign.end,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: usePercent ? '%' : store.currency.code,
                          ),
                          onTap: () {
                            // If the field is already focused, still select all on tap
                            final ctrl = ctrls[c.id]!;
                            if (_isDisplayedZero(ctrl.text)) {
                              ctrl.clear();
                            } else {
                              ctrl.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: ctrl.text.length,
                              );
                            }
                          },
                          onChanged: (v) => _onChangedFor(c.id, v),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final res = await showDialog<(String, String)?>(
                        context: context,
                        builder: (_) => const AddCategoryDialog(),
                      );
                      if (res != null) {
                        final (name, emoji) = res;
                        final newCat = store.addCategory(name, emoji);

                        draftAmounts[newCat.id] = 0.0;

                        final text = usePercent ? '0' : _fmtAmount(0.0);
                        ctrls[newCat.id] = TextEditingController(text: text);
                        _ensureFocusNode(newCat.id);

                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add category'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: !canSave
                  ? null
                  : () {
                      try {
                        final total = b.categories.fold<double>(
                          0.0,
                          (s, c) => s + (draftAmounts[c.id] ?? 0.0),
                        );

                        if (total > _totalIncome + 1e-6) {
                          throw Exception(
                              'Total allocations exceed total income.');
                        }

                        // Save totals (not incremental)
                        store.setAllocationsByAmounts(
                            Map<String, double>.from(draftAmounts));

                        if (!mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Allocations updated.')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
              child: const Text('Save allocations'),
            ),
          ],
        ),
      ),
    );
  }
}

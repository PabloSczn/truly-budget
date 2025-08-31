import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/budget_store.dart';
import '../widgets/emoji_selector.dart';
import 'allocate_income_screen.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _EmojiPrefixButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;
  const _EmojiPrefixButton({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 20,
        onPressed: onTap,
        tooltip: 'Choose emoji',
        // Nudge the emoji slightly down to align with the text baseline
        icon: Transform.translate(
          offset: const Offset(1, 6),
          child: Text(
            emoji,
            style: const TextStyle(
              fontSize: 22,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final sourceCtrl = TextEditingController(text: 'Salary');
  final amountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String leadingEmoji = '💼';

  @override
  void dispose() {
    sourceCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _insertEmojiFromPicker() async {
    final e = await pickEmoji(context);
    if (e == null || e.isEmpty) return;
    setState(() => leadingEmoji = e);

    // Insert at caret
    final t = sourceCtrl;
    final sel = t.selection;
    final start = sel.start < 0 ? t.text.length : sel.start;
    final end = sel.end < 0 ? t.text.length : sel.end;
    t.value = TextEditingValue(
      text: t.text.replaceRange(start, end, e),
      selection: TextSelection.collapsed(offset: start + e.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Add income')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Source field with emoji button
              TextFormField(
                controller: sourceCtrl,
                decoration: InputDecoration(
                  labelText: 'From where?',
                  // Tightly-sized, click-only emoji button
                  prefixIcon: _EmojiPrefixButton(
                    emoji: leadingEmoji,
                    onTap: _insertEmojiFromPicker,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                    maxWidth: 52,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please describe the income source'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    signed: false, decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount in ${store.currency.code}',
                  prefixIcon: const Icon(Icons.numbers),
                ),
                validator: (v) {
                  final d = double.tryParse(v?.replaceAll(',', '.') ?? '');
                  if (d == null || d <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final amount =
                        double.parse(amountCtrl.text.replaceAll(',', '.'));
                    store.addIncome(sourceCtrl.text.trim(), amount);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AllocateIncomeScreen(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add income & allocate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/budget_store.dart';
import '../widgets/emoji_selector.dart';
import '../widgets/money_amount_form_field.dart';

class AddIncomeScreen extends StatefulWidget {
  final int? incomeIndex;
  final String initialSource;
  final double? initialAmount;
  final DateTime? initialDate;

  const AddIncomeScreen({
    super.key,
    this.incomeIndex,
    this.initialSource = 'Salary',
    this.initialAmount,
    this.initialDate,
  });

  bool get isEditing => incomeIndex != null;

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
  late final TextEditingController sourceCtrl;
  late final TextEditingController amountCtrl;
  final _formKey = GlobalKey<FormState>();
  late String leadingEmoji;

  @override
  void initState() {
    super.initState();
    sourceCtrl = TextEditingController(text: widget.initialSource);
    amountCtrl = TextEditingController(
      text: widget.initialAmount == null
          ? ''
          : _formatInitialAmount(widget.initialAmount!),
    );
    leadingEmoji = _leadingEmojiFor(widget.initialSource);
  }

  @override
  void dispose() {
    sourceCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  String _leadingEmojiFor(String source) {
    final trimmed = source.trimLeft();
    if (trimmed.isEmpty) return '💼';

    final first = trimmed.characters.first;
    if (RegExp(r'^[A-Za-z0-9]$').hasMatch(first)) {
      return '💼';
    }
    return first;
  }

  String _formatInitialAmount(double amount) {
    return amount
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _messageFromError(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw.isEmpty ? 'Something went wrong.' : raw;
  }

  Future<void> _pickLeadingEmoji() async {
    final e = await pickEmoji(context);
    if (e == null || e.isEmpty) return;
    setState(() => leadingEmoji = e);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(amountCtrl.text.replaceAll(',', '.'));
    final store = context.read<BudgetStore>();

    try {
      if (widget.isEditing) {
        store.updateIncome(
          widget.incomeIndex!,
          source: sourceCtrl.text.trim(),
          amount: amount,
          date: widget.initialDate,
        );
      } else {
        store.addIncome(sourceCtrl.text.trim(), amount);
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFromError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit income' : 'Add income'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                      onTap: _pickLeadingEmoji,
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
                MoneyAmountFormField(
                  controller: amountCtrl,
                  currencySymbol: store.currency.symbol,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton.icon(
          onPressed: _submit,
          icon: Icon(widget.isEditing ? Icons.save_outlined : Icons.add),
          label: Text(widget.isEditing ? 'Save changes' : 'Add income'),
        ),
      ),
    );
  }
}

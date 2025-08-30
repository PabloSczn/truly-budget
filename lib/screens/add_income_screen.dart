import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/budget_store.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final sourceCtrl = TextEditingController(text: '💼 Salary');
  final amountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    sourceCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
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
              TextFormField(
                controller: sourceCtrl,
                decoration: const InputDecoration(
                  labelText: 'From where? (you can include an emoji)',
                  prefixIcon: Icon(Icons.short_text),
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
                    // After income, go straight to Allocate screen
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const _GoAllocateAfterIncome()),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add income & allocate'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _GoAllocateAfterIncome extends StatelessWidget {
  const _GoAllocateAfterIncome();

  @override
  Widget build(BuildContext context) {
    // redirect into AllocateIncomeScreen so user can allocate immediately
    Future.microtask(() {
      Navigator.of(context).pushReplacementNamed('/allocate');
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

import 'package:flutter/material.dart';

InputDecoration moneyAmountInputDecoration(
  BuildContext context, {
  required String currencySymbol,
  String? labelText = 'Amount',
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final prefixStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      );

  return InputDecoration(
    labelText: labelText,
    prefixText: '$currencySymbol ',
    prefixStyle: prefixStyle,
  );
}

class MoneyAmountFormField extends StatefulWidget {
  final TextEditingController controller;
  final String currencySymbol;
  final String labelText;
  final FocusNode? focusNode;
  final bool selectAllOnFocus;

  const MoneyAmountFormField({
    super.key,
    required this.controller,
    required this.currencySymbol,
    this.labelText = 'Amount',
    this.focusNode,
    this.selectAllOnFocus = false,
  });

  @override
  State<MoneyAmountFormField> createState() => _MoneyAmountFormFieldState();
}

class _MoneyAmountFormFieldState extends State<MoneyAmountFormField> {
  FocusNode? _internalFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode == null ? FocusNode() : null;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant MoneyAmountFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    oldWidget.focusNode?.removeListener(_handleFocusChange);
    _internalFocusNode?.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _internalFocusNode = widget.focusNode == null ? FocusNode() : null;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!widget.selectAllOnFocus || !_focusNode.hasFocus) return;
    final text = widget.controller.text;
    if (text.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasFocus) return;
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: const TextInputType.numberWithOptions(
        signed: false,
        decimal: true,
      ),
      decoration: moneyAmountInputDecoration(
        context,
        currencySymbol: widget.currencySymbol,
        labelText: widget.labelText,
      ),
      validator: (value) {
        final amount = double.tryParse(value?.replaceAll(',', '.') ?? '');
        if (amount == null || amount <= 0) return 'Enter a valid amount';
        return null;
      },
    );
  }
}

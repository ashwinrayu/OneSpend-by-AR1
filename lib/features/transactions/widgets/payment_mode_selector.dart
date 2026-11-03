import 'package:flutter/material.dart';
import '../../../models/enums.dart';

class PaymentModeSelector extends StatelessWidget {
  final PaymentMethod selectedMode;
  final ValueChanged<PaymentMethod> onSelected;

  const PaymentModeSelector({
    super.key,
    required this.selectedMode,
    required this.onSelected,
  });

  IconData _iconForMode(PaymentMethod mode) {
    switch (mode) {
      case PaymentMethod.upi:
        return Icons.qr_code_scanner_rounded;
      case PaymentMethod.creditCard:
        return Icons.credit_card_rounded;
      case PaymentMethod.bank:
        return Icons.account_balance_rounded;
      case PaymentMethod.cash:
        return Icons.payments_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMethod.values.map((mode) {
        final isSelected = selectedMode == mode;

        return ChoiceChip(
          avatar: Icon(
            _iconForMode(mode),
            size: 16,
            color: isSelected ? Colors.white : theme.colorScheme.primary,
          ),
          label: Text(mode.displayName),
          selected: isSelected,
          onSelected: (val) {
            if (val) onSelected(mode);
          },
        );
      }).toList(),
    );
  }
}


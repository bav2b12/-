import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';

class DebtAmountText extends StatelessWidget {
  const DebtAmountText({
    super.key,
    required this.amount,
    this.large = false,
  });

  final double amount;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final settled = amount <= 0.0001;
    return Text(
      Money.format(amount),
      style: (large
              ? Theme.of(context).textTheme.headlineSmall
              : Theme.of(context).textTheme.titleMedium)
          ?.copyWith(
        color: settled ? AlantonyTheme.settledGreen : AlantonyTheme.debtRed,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

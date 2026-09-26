import 'package:intl/intl.dart';

import 'constants.dart';

class Money {
  static final NumberFormat _format = NumberFormat.decimalPattern('ar');

  static String format(num amount) {
    return '${_format.format(amount)} ${AppConstants.currency}';
  }
}

String formatTimestamp(DateTime date) {
  return DateFormat('d MMMM yyyy  •  h:mm a', 'ar').format(date);
}

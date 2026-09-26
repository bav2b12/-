import 'package:flutter_test/flutter_test.dart';

import 'package:alantony/core/validators.dart';

void main() {
  test('normalizes and validates room codes', () {
    expect(Validators.normalizeRoomCode('ant-892'), 'ANT892');
    expect(Validators.roomCode('ANT892'), isNull);
    expect(Validators.roomCode('ab'), isNotNull);
  });

  test('accepts only positive money amounts', () {
    expect(Validators.positiveMoney('10.5'), isNull);
    expect(Validators.positiveMoney('0'), isNotNull);
    expect(Validators.positiveMoney('-3'), isNotNull);
    expect(Validators.positiveMoney('abc'), isNotNull);
    expect(Validators.parseMoney('12,5'), 12.5);
  });
}

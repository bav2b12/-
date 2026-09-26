import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

String friendlyError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'network-request-failed':
        return 'لا يوجد اتصال حالياً. أعد المحاولة بعد عودة الشبكة.';
      case 'account-exists-with-different-credential':
        return 'هذا الحساب مرتبط بطريقة دخول أخرى.';
      default:
        return 'تعذر إكمال تسجيل الدخول. حاول مرة أخرى.';
    }
  }
  final text = error.toString();
  if (text.contains('network') || text.contains('SocketException')) {
    return 'لا يوجد اتصال حالياً. يمكنك المتابعة بعد عودة الشبكة.';
  }
  if (error is StateError) return error.message;
  return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
}

void showAppSnackBar(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

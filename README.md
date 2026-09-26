# الأنطوني — إدارة ديون العملاء

تطبيق Flutter متعدد المنصات لإدارة ديون عملاء متجر **الأنطوني**. يعمل أولاً بدون إنترنت (Offline-first) عبر Cloud Firestore، ثم يزامن البيانات تلقائياً عند عودة الاتصال. تسجيل الدخول عبر Google.

## المتطلبات

- Flutter SDK 3.24+ (`flutter doctor` يجب أن يكون سليماً)
- حساب Firebase مع تفعيل **Authentication (Google)** و **Cloud Firestore**
- ملف `google-services.json` من وحدة تحكم Firebase

## إعداد Firebase

### 1) إنشاء المشروع والتطبيق

1. أنشئ مشروعاً في [Firebase Console](https://console.firebase.google.com).
2. أضف تطبيق Android بمعرّف الحزمة:

   `com.alantony.debts`

3. نزّل `google-services.json` وضعه هنا:

   `android/app/google-services.json`

4. أضف تطبيق iOS إن لزم، وضَع `GoogleService-Info.plist` في `ios/Runner/`.
5. (اختياري) نفّذ `flutterfire configure` لتوليد `lib/firebase_options.dart`. التطبيق يعمل على أندرويد بدون هذا الملف طالما `google-services.json` موجود.

### 2) SHA-1 لتسجيل Google (أندرويد)

بدون بصمة SHA لن يعمل زر Google على الأجهزة الحقيقية/المحاكي:

```bash
cd android
./gradlew signingReport
```

أو:

```bash
keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android
```

أضف SHA-1 (و SHA-256) في إعدادات تطبيق Android داخل Firebase، ثم نزّل `google-services.json` من جديد.

فعّل **Google** من Authentication → Sign-in method.

### 3) قواعد Firestore

من مجلد المشروع:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

أو انسخ محتوى `firestore.rules` يدوياً إلى تبويب Rules.

### 4) التخزين المؤقت دون اتصال

التطبيق يفعّل الإعداد صراحة عند الإقلاع:

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

القراءة والكتابة والبحث تعمل من الكاش عند انقطاع الشبكة، ثم تُزامَن تلقائياً.

## التشغيل

ثبّت [Flutter](https://docs.flutter.dev/get-started/install) وأضفه إلى PATH، ثم من مجلد المشروع:

```bash
flutter create . --project-name alantony --org com.alantony --platforms=android,ios,web
flutter pub get
flutter run
```

الأمر `flutter create .` يُكمل ملفات المنصات الناقصة (مثل Gradle Wrapper ومشروع Xcode) دون حذف كود `lib/`. بعد ذلك استبدل `android/app/google-services.json` بالنسخة الحقيقية من Firebase.

## نموذج البيانات

| المسار | الوصف |
| --- | --- |
| `rooms/{code}` | الغرفة/المتجر. معرّف المستند = كود من 6 أحرف |
| `rooms/{code}/customers/{id}` | العملاء ورصيد الدين |
| `rooms/{code}/customers/{id}/transactions/{id}` | حركات الدين والسداد |

كل الاستعلامات مقيّدة بـ `room_id` النشط المحفوظ محلياً عبر `shared_preferences`.

## الغرف

- **إنشاء غرفة:** اسم المتجر + توليد كود فريد (6 أحرف كبيرة وأرقام)، المالك هو المستخدم الحالي.
- **انضمام:** إدخال الكود والتحقق من مجموعة `rooms`.
- **تغيير الغرفة:** من الإعدادات يُمسح الربط المحلي دون حذف بيانات السحابة.

## ملاحظات الاستخدام دون إنترنت

- جلسة Google تُحفظ بعد أول تسجيل دخول ناجح.
- لا تظهر أعطال قاتلة عند الكتابة بدون شبكة؛ Firestore يضعها في قائمة الانتظار.
- شريط أعلى الشاشة يوضح حالة الاتصال فقط.

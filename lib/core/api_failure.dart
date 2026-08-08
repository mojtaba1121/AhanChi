import 'package:dio/dio.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiFailure.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final serverMessage = _extractMessage(error.response?.data);
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return ApiFailure(_translateValidationMessage(serverMessage), statusCode: statusCode);
    }

    final message = switch (error.type) {
      DioExceptionType.connectionTimeout => 'زمان اتصال به سرور تمام شد؛ اینترنت و آدرس سرور را بررسی کنید',
      DioExceptionType.sendTimeout => 'ارسال اطلاعات به سرور بیش از حد طول کشید؛ دوباره تلاش کنید',
      DioExceptionType.receiveTimeout => 'پاسخ سرور بیش از حد طول کشید؛ دوباره تلاش کنید',
      DioExceptionType.connectionError => 'ارتباط با سرور برقرار نشد؛ اینترنت، آدرس و روشن‌بودن سرور را بررسی کنید',
      DioExceptionType.badCertificate => 'گواهی امنیتی سرور معتبر نیست',
      DioExceptionType.cancel => 'درخواست لغو شد',
      DioExceptionType.badResponse when statusCode == 401 => 'شماره موبایل یا رمز عبور اشتباه است',
      DioExceptionType.badResponse when statusCode == 403 => 'شما اجازه انجام این عملیات را ندارید',
      DioExceptionType.badResponse when statusCode == 404 => 'مسیر درخواستی روی سرور پیدا نشد',
      DioExceptionType.badResponse when statusCode != null && statusCode >= 500 => 'سرور با خطا مواجه شد؛ کمی بعد دوباره تلاش کنید',
      _ => 'خطای غیرمنتظره‌ای رخ داد؛ دوباره تلاش کنید',
    };
    return ApiFailure(message, statusCode: statusCode);
  }

  @override
  String toString() => message;
}

String friendlyErrorMessage(Object? error) {
  if (error is ApiFailure) return error.message;
  final message = error?.toString().trim() ?? '';
  if (message.isEmpty) return 'خطای غیرمنتظره‌ای رخ داد؛ دوباره تلاش کنید';
  return message.replaceFirst(RegExp(r'^(Exception|Error):\s*'), '');
}

String? _extractMessage(Object? data) {
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is String) return message;
    if (message is List) return message.map((item) => item.toString()).join('، ');
  }
  if (data is String) return data;
  return null;
}

String _translateValidationMessage(String message) {
  final translations = <String, String>{
    'phone must match': 'شماره موبایل باید با ۰۹ شروع شود و ۱۱ رقم باشد',
    'password must be longer than or equal to 8 characters': 'رمز عبور باید حداقل ۸ کاراکتر باشد',
    'fullName must be longer than or equal to 2 characters': 'نام کامل باید حداقل ۲ کاراکتر باشد',
    'role must be one of the following values': 'نوع کاربر معتبر نیست',
  };
  for (final entry in translations.entries) {
    if (message.contains(entry.key)) return entry.value;
  }
  return message;
}

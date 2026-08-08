import 'package:ahanchi/core/api_failure.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses a server-provided Persian error message', () {
    final request = RequestOptions(path: '/users');
    final error = DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: request,
        statusCode: 409,
        data: {'message': 'این شماره موبایل قبلاً ثبت شده است'},
      ),
    );

    expect(ApiFailure.fromDio(error).message, 'این شماره موبایل قبلاً ثبت شده است');
  });

  test('turns connection errors into an actionable message', () {
    final failure = ApiFailure.fromDio(DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      type: DioExceptionType.connectionError,
    ));

    expect(failure.message, contains('ارتباط با سرور برقرار نشد'));
  });

  test('keeps the not-found status and seller message for sync recovery', () {
    final request = RequestOptions(path: '/purchases');
    final failure = ApiFailure.fromDio(DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: request,
        statusCode: 404,
        data: {'message': 'فروشنده پیدا نشد'},
      ),
    ));

    expect(failure.statusCode, 404);
    expect(failure.message, 'فروشنده پیدا نشد');
  });
}

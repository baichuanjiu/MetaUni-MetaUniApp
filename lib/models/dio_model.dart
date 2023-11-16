import 'package:dio/dio.dart';

class DioModel {
  Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:45550',
    ),
  );
}

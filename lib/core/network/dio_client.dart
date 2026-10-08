import 'package:dio/dio.dart';

import '../config/app_config.dart';

Dio createDioClient() {
  return Dio(
    BaseOptions(
      baseUrl: AppConfig.stdictBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
}

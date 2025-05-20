// import 'package:dio/dio.dart';

// class DioHelper {
//   static Dio? _dio;
  
//   static Dio get dio {
//     _dio ??= _createDio();
//     return _dio!;
//   }

//   static Dio _createDio() {
//     final dio = Dio(
//       BaseOptions(
//         connectTimeout: const Duration(seconds: 30),
//         receiveTimeout: const Duration(seconds: 30),
//         sendTimeout: const Duration(seconds: 30),
//         validateStatus: (status) {
//           return status! < 500;
//         },
//       ),
//     );

//     // Add interceptors if needed
//     dio.interceptors.add(LogInterceptor(
//       request: true,
//       requestHeader: true,
//       requestBody: true,
//       responseHeader: true,
//       responseBody: true,
//       error: true,
//     ));

//     return dio;
//   }

//   static Future<Response> post(
//     String url, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//     CancelToken? cancelToken,
//     ProgressCallback? onSendProgress,
//     ProgressCallback? onReceiveProgress,
//   }) async {
//     try {
//       final response = await dio.post(
//         url,
//         data: data,
//         queryParameters: queryParameters,
//         options: options,
//         cancelToken: cancelToken,
//         onSendProgress: onSendProgress,
//         onReceiveProgress: onReceiveProgress,
//       );
//       return response;
//     } catch (e) {
//       rethrow;
//     }
//   }
// }
import 'package:dio/dio.dart';

import '../models/deezer_model.dart';

class SongService {
  final Dio _dio;

  SongService()
    : _dio = Dio(
        BaseOptions(
          receiveTimeout: const Duration(seconds: 100),
          connectTimeout: const Duration(seconds: 100),
          baseUrl: 'https://api.deezer.com/track/',
        ),
      );

  Future<DeezerSongModel> getTrack(String id) async {
    try {
      final response = await _dio.get(
        id,
        options: Options(
          headers: {
            'Content-Type': 'application/json;charset=UTF-8',
            'Accept': 'application/json;charset=UTF-8',
          },
        ),
      );

      return DeezerSongModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        // Server responded with an error
        print('DioException Response: ${e.response?.data}');
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        // Other errors (timeout, no internet, etc.)
        print('DioException: ${e.message}');
        throw Exception('Connection error: ${e.message}');
      }
    } catch (e) {
      print('Unhandled error: $e');
      rethrow;
    }
  }
}

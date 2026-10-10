import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/json.dart';

/// Fayl yuklash — `POST /media/upload` (multipart, maydon nomi `file`).
///
/// Javobdagi `url` boshqa so'rovlarda ishlatiladi (masalan mashinaning
/// `tech_passport_photo` maydoni). Rasmni backend saqlaydi, ilova faqat
/// URL bilan ishlaydi.
class MediaRepository {
  MediaRepository(this._client);

  final ApiClient _client;

  Future<String?> upload(String filePath, {String? fileName}) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final res = await _client.dio.post<dynamic>(
        '/media/upload',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final body = asMap(unwrap(res.data));
      final url = asString(body?['url']);
      return url.isEmpty ? null : url;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

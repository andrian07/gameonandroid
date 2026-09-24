import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'apiUrl.dart';

/// Dilempar ApiService kalau request gagal karena TIDAK ADA KONEKSI JARINGAN
/// (offline, DNS gagal, timeout, dll) - beda dari error server/parsing biasa,
/// supaya pemanggil bisa tampilkan pesan yang lebih tepat ("Gagal terhubung
/// ke jaringan") alih-alih pesan generik "server sedang gangguan".
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = "Gagal terhubung ke jaringan"]);

  @override
  String toString() => message;
}

class ApiService {
  /// Bungkus [http.post] supaya error koneksi (offline/DNS/timeout) selalu
  /// muncul sebagai [NetworkException], apapun penyebab detailnya.
  Future<http.Response> _post(Uri uri, Map<String, String> headers,
      Map<String, dynamic> body) async {
    try {
      return await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException();
    }
  }

  /// [endpoint] adalah path relatif (mis. ApiUrl.login), digabung dengan
  /// ApiUrl.baseUrl di sini sehingga base URL cukup diubah di satu tempat.
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await _post(
      Uri.parse("${ApiUrl.baseUrl}$endpoint"),
      {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body,
    );

    return jsonDecode(response.body);
  }

  /// Sama seperti [post], tapi menyertakan header Authorization: Bearer [token]
  /// untuk endpoint yang butuh autentikasi.
  Future<dynamic> postAuth(
    String endpoint,
    Map<String, dynamic> body,
    String token,
  ) async {
    final response = await _post(
      Uri.parse("${ApiUrl.baseUrl}$endpoint"),
      {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body,
    );

    return jsonDecode(response.body);
  }
}

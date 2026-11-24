import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiError implements Exception {
  const ApiError(this.message, this.status);
  final String message;
  final int status;
  @override
  String toString() => message;
}

class BacaTepatApi {
  static String get base {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/+$'), '');
    }
    if (kIsWeb) return '${Uri.base.origin}/api/v1';
    final host = defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
    return 'http://$host:8000/api/v1';
  }

  static const storage = FlutterSecureStorage();
  String get storageKey => 'bacatepat.session.${Uri.encodeComponent(base)}';
  String? _token;
  VoidCallback? onExpired;

  Future<void> _checkSession(int status) async {
    if (status == 401 && _token != null) {
      await forget();
      onExpired?.call();
    }
  }

  Future<http.Response> _send(http.BaseRequest request) async {
    return http.Response.fromStream(await request.send());
  }

  Future<Map<String, dynamic>?> restore() async {
    _token = await storage.read(key: storageKey);
    if (_token == null) return null;
    try {
      return (await request('auth/me'))['data'] as Map<String, dynamic>;
    } on ApiError catch (e) {
      if (e.status != 401 && e.status != 403) rethrow;
      await forget();
      return null;
    }
  }

  Future<void> forget() async {
    _token = null;
    await storage.delete(key: storageKey);
  }

  Future<Map<String, dynamic>> request(
    String path, {
    Map<String, dynamic>? body,
    String? method,
  }) async {
    final uri = Uri.parse('$base/$path');
    final headers = {
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
      if (body != null) 'Content-Type': 'application/json',
    };
    final http.Response response;
    try {
      final request = http.Request(
        method ?? (body == null ? 'GET' : 'POST'),
        uri,
      )..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      response = await _send(request).timeout(const Duration(seconds: 15));
    } on http.ClientException {
      throw const ApiError('Server tidak dapat dihubungi.', 0);
    } on TimeoutException {
      throw const ApiError('Server belum merespons. Coba lagi.', 0);
    }
    await _checkSession(response.statusCode);
    if (response.statusCode >= 500 && response.statusCode != 503) {
      throw const ApiError('Terjadi gangguan pada server.', 500);
    }
    final Map<String, dynamic> result;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      result = decoded;
    } on FormatException {
      throw ApiError(
        'Respons server tidak dapat dibaca. Periksa alamat API.',
        response.statusCode,
      );
    }
    if (response.statusCode >= 400) {
      throw ApiError(
        result['message'] as String? ?? 'Permintaan gagal.',
        response.statusCode,
      );
    }
    return result;
  }

  Future<Map<String, dynamic>> login(
    String username,
    String password,
    String role,
  ) async {
    final result = await request(
      'auth/login',
      body: {
        'username': username,
        'password': password,
        'device_name': 'flutter',
        'role': role,
      },
    );
    _token = result['data']['token'] as String;
    await storage.write(key: storageKey, value: _token);
    return result['data']['user'] as Map<String, dynamic>;
  }

  Future<void> uploadRecording(
    List<int> bytes,
    String name,
    Map<String, String> fields,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$base/siswa/rekaman'),
    );
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $_token',
    });
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: name),
    );
    try {
      final response = await _send(request)
          .timeout(const Duration(seconds: 60));
      await _checkSession(response.statusCode);
      if (response.statusCode >= 400) {
        throw ApiError(
          response.statusCode >= 500
              ? 'Pemeriksaan rekaman belum tersedia.'
              : jsonDecode(response.body)['message'] ?? 'Unggah gagal.',
          response.statusCode,
        );
      }
    } on http.ClientException {
      throw const ApiError('Server tidak dapat dihubungi.', 0);
    } on TimeoutException {
      throw const ApiError('Batas waktu unggah terlampaui.', 0);
    }
  }

  Future<Uint8List> download(String path) async {
    final response = await http
        .get(
          Uri.parse('$base/$path'),
          headers: {'Authorization': 'Bearer $_token', 'Accept': '*/*'},
        )
        .timeout(const Duration(seconds: 30));
    await _checkSession(response.statusCode);
    if (response.statusCode != 200) {
      throw ApiError('Berkas tidak tersedia.', response.statusCode);
    }
    return response.bodyBytes;
  }

  Future<void> logout() async {
    try {
      await request('auth/logout', body: {});
    } on ApiError catch (e) {
      if (e.status != 401) rethrow;
    }
    await forget();
  }
}

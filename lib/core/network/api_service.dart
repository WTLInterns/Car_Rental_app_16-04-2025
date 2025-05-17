import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/app_exception.dart';

class ApiService {
  final String baseUrl;
  
  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseApiUrl;
  
  Future<dynamic> get(String endpoint) async {
    dynamic responseJson;
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      responseJson = _returnResponse(response);
    } on Exception catch (e) {
      throw NetworkException(e.toString());
    }
    return responseJson;
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    dynamic responseJson;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      responseJson = _returnResponse(response);
    } on Exception catch (e) {
      throw NetworkException(e.toString());
    }
    return responseJson;
  }
  
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    dynamic responseJson;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      responseJson = _returnResponse(response);
    } on Exception catch (e) {
      throw NetworkException(e.toString());
    }
    return responseJson;
  }
  
  Future<dynamic> delete(String endpoint, {dynamic body}) async {
    dynamic responseJson;
    try {
      final response = body != null
          ? await http.delete(
              Uri.parse('$baseUrl$endpoint'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body),
            )
          : await http.delete(Uri.parse('$baseUrl$endpoint'));
      
      responseJson = _returnResponse(response);
    } on Exception catch (e) {
      throw NetworkException(e.toString());
    }
    return responseJson;
  }
  
  dynamic _returnResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        if (response.body.isEmpty) {
          return {};
        }
        
        try {
          final responseJson = json.decode(response.body);
          return responseJson;
        } on FormatException {
          throw BadResponseException("Invalid response format");
        }
      case 400:
        throw BadRequestException(response.body);
      case 401:
      case 403:
        throw UnauthorizedException(response.body);
      case 404:
        throw NotFoundException(response.body);
      case 500:
      default:
        throw ServerException('Server error with status code: ${response.statusCode}');
    }
  }
} 
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() {
    return 'ApiException: $message (Status code: $statusCode)';
  }
}

/// Process the HTTP response and handle errors
Map<String, dynamic> _processResponse(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    final decodedBody = json.decode(response.body);
    if (decodedBody is Map<String, dynamic>) {
      return decodedBody;
    } else {
      // Handle cases where the response body is not a JSON object
      // Or throw a more specific error if a JSON object is always expected
      throw ApiException(
        message: 'Unexpected response format',
        statusCode: response.statusCode,
      );
    }
  } else {
    String errorMessage = 'Unknown error';
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map && errorBody.containsKey('error')) {
        errorMessage = errorBody['error']?.toString() ?? 'Unknown error message';
      } else if (errorBody is String) {
        errorMessage = errorBody;
      } else if (response.reasonPhrase != null && response.reasonPhrase!.isNotEmpty) {
        errorMessage = response.reasonPhrase!;
      }
    } catch (e) {
      // If decoding fails or it's not a map, use the reason phrase or a generic message
      errorMessage = response.reasonPhrase ?? 'Failed to process error response';
    }
    throw ApiException(
      message: errorMessage,
      statusCode: response.statusCode,
    );
  }
}

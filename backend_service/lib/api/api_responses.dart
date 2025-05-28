import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Helper class for creating standardized API responses
class ApiResponseHelper {
  /// Creates a JSON response with custom data
  static Response jsonResponse(String data) {
    return Response.ok(
      data,
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }
  
  /// Creates a success response with optional data
  static Response successResponse(String message, [Map<String, dynamic>? data]) {
    final Map<String, Object> response = {'success': true, 'message': message};
    if (data != null) {
      response.addAll(data.map((key, value) => MapEntry(key, value as Object)));
    }
    return Response.ok(
      jsonEncode(response),
      headers: {'content-type': 'application/json'}
    );
  }
  
  /// Creates an error response with optional status code
  static Response errorResponse(String message, [int statusCode = 400]) {
    return Response(
      statusCode,
      body: jsonEncode({
        'success': false,
        'error': message,
      }),
      headers: {'content-type': 'application/json'}
    );
  }
}

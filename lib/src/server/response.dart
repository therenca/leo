import 'dart:io';
import 'dart:convert';

/// HTTP Response class that encapsulates status code, headers, and body
class Response {
  final int statusCode;
  final Map<String, String> headers;
  final dynamic body;
  final ContentType? contentType;

  Response({
    required this.statusCode,
    this.headers = const {},
    this.body,
    this.contentType,
  });

  /// Creates a successful 200 OK response
  factory Response.ok({
    dynamic body,
    Map<String, String> headers = const {},
    ContentType? contentType,
  }) {
    return Response(
      statusCode: 200,
      body: body,
      headers: headers,
      contentType: contentType,
    );
  }

  /// Creates a JSON response with 200 OK status
  factory Response.json(
    Map<String, dynamic> data, {
    int statusCode = 200,
    Map<String, String> headers = const {},
  }) {
    return Response(
      statusCode: statusCode,
      body: data,
      headers: headers,
      contentType: ContentType.json,
    );
  }

  /// Creates a plain text response
  factory Response.text(
    String text, {
    int statusCode = 200,
    Map<String, String> headers = const {},
  }) {
    return Response(
      statusCode: statusCode,
      body: text,
      headers: headers,
      contentType: ContentType.text,
    );
  }

  /// Creates an HTML response
  factory Response.html(
    String html, {
    int statusCode = 200,
    Map<String, String> headers = const {},
  }) {
    return Response(
      statusCode: statusCode,
      body: html,
      headers: headers,
      contentType: ContentType.html,
    );
  }

  /// Creates a 404 Not Found response
  factory Response.notFound({
    dynamic body = 'Not Found',
    Map<String, String> headers = const {},
  }) {
    return Response(
      statusCode: 404,
      body: body,
      headers: headers,
      contentType: ContentType.text,
    );
  }

  /// Creates a 400 Bad Request response
  factory Response.badRequest({
    dynamic body = 'Bad Request',
    Map<String, String> headers = const {},
  }) {
    return Response(
      statusCode: 400,
      body: body,
      headers: headers,
      contentType: ContentType.text,
    );
  }

  /// Creates a 401 Unauthorized response
  factory Response.unauthorized({
    dynamic body = 'Unauthorized',
    Map<String, String> headers = const {},
  }) {
    return Response(
      statusCode: 401,
      body: body,
      headers: headers,
      contentType: ContentType.text,
    );
  }

  /// Creates a 403 Forbidden response
  factory Response.forbidden({
    dynamic body = 'Forbidden',
    Map<String, String> headers = const {},
  }) {
    return Response(
      statusCode: 403,
      body: body,
      headers: headers,
      contentType: ContentType.text,
    );
  }

  /// Creates a 500 Internal Server Error response
  factory Response.internalServerError({
    dynamic body = 'Internal Server Error',
    Map<String, String> headers = const {},
  }) {
    return Response(
      statusCode: 500,
      body: body,
      headers: headers,
      contentType: ContentType.text,
    );
  }

  /// Creates a redirect response
  factory Response.redirect(
    String location, {
    int statusCode = 302,
    Map<String, String> headers = const {},
  }) {
    final redirectHeaders = Map<String, String>.from(headers);
    redirectHeaders['Location'] = location;
    return Response(
      statusCode: statusCode,
      headers: redirectHeaders,
    );
  }

  /// Creates an empty response with just a status code
  factory Response.status(int statusCode) {
    return Response(statusCode: statusCode);
  }

  /// Writes this response to an HttpResponse
  Future<void> writeTo(HttpResponse httpResponse) async {
    httpResponse.statusCode = statusCode;
    
    // Set content type if specified
    if (contentType != null) {
      httpResponse.headers.contentType = contentType;
    }
    
    // Set custom headers
    headers.forEach((key, value) {
      httpResponse.headers.set(key, value);
    });
    
    // Write body if present
    if (body != null) {
      if (body is String) {
        httpResponse.write(body);
      } else if (body is Map || body is List) {
        if (contentType?.mimeType == 'application/json' || contentType == null) {
          httpResponse.headers.contentType = ContentType.json;
          httpResponse.write(jsonEncode(body));
        } else {
          httpResponse.write(body.toString());
        }
      } else if (body is List<int>) {
        httpResponse.add(body);
      } else {
        httpResponse.write(body.toString());
      }
    }
    
    await httpResponse.close();
  }
}

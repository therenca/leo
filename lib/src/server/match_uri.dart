import 'server.dart' as server;
import 'http_route.dart' as http_route;

class MatchUri {
  /// Generic method to match any HTTP method route
  static String? match(
      Map<String, server.RequestHandler> routes, http_route.Route route) {
    // Use entries.firstWhere for early termination instead of forEach
    try {
      final entry = routes.entries.firstWhere((entry) {
        final pattern = entry.key;
        final routeClass = _createRouteFromMethod(route.httpMethod, pattern);
        return route == routeClass;
      });
      return entry.key;
    } catch (e) {
      // No matching route found
      return null;
    }
  }

  /// Create appropriate route class based on HTTP method
  static http_route.Route _createRouteFromMethod(
      http_route.HttpMethod method, String pattern) {
    switch (method) {
      case http_route.HttpMethod.GET:
        return http_route.GET(pattern);
      case http_route.HttpMethod.POST:
        return http_route.POST(pattern);
      case http_route.HttpMethod.PUT:
        return http_route.PUT(pattern);
      case http_route.HttpMethod.DELETE:
        return http_route.DELETE(pattern);
      case http_route.HttpMethod.PATCH:
        return http_route.PATCH(pattern);
      case http_route.HttpMethod.OPTIONS:
        return http_route.OPTIONS(pattern);
      case http_route.HttpMethod.HEAD:
        return http_route.HEAD(pattern);
    }
  }

}
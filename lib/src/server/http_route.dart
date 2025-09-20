import 'dart:io';

enum HttpMethod {
  GET('GET'),
  POST('POST'),
  PUT('PUT'),
  DELETE('DELETE'),
  PATCH('PATCH'),
  OPTIONS('OPTIONS'),
  HEAD('HEAD');

  const HttpMethod(this.value);
  final String value;

  static HttpMethod fromString(String method) {
    return HttpMethod.values.firstWhere(
      (m) => m.value == method.toUpperCase(),
      orElse: () => throw ArgumentError('Unsupported HTTP method: $method'),
    );
  }
}

class Route {
  final HttpMethod httpMethod;
  final String uriPath;
  String? matchedWith;
  List<String>? _params;
  Map<String, int>? _paramIndices;

  HttpRequest? req;

  Route(this.httpMethod, this.uriPath, [this.req]);

  // Backward compatibility getter
  String get method => httpMethod.value;

  String? param(String param) {
    if (!_paramIndices!.containsKey(param)) {
      return null;
    }

    return this._params![_paramIndices![param]!];
  }

  String toString() => '${httpMethod.value} $uriPath';
  Route fromString(String str) {
    final chunks = str.split(' ');
    return Route(HttpMethod.fromString(chunks[0]), chunks[1]);
  }

  // ignore: non_nullable_equals_parameter
  bool operator ==(dynamic other) {
    if (!(other is Route)) {
      return false;
    }

    if (other is GET && this.httpMethod != HttpMethod.GET) return false;

    final ownPathSegments =
        this.uriPath.split('/').where((c) => c.isNotEmpty).toList();
    final otherPathSegments =
        other.uriPath.split('/').where((c) => c.isNotEmpty).toList();

    if (ownPathSegments.length != otherPathSegments.length) return false;

    while (true) {
      if (ownPathSegments.length == 0) break;

      if (otherPathSegments.first.startsWith(':') ||
          ownPathSegments.first.startsWith(':')) break;

      final ownSegment = ownPathSegments.removeAt(0);
      final otherSegment = otherPathSegments.removeAt(0);

      if (ownSegment != otherSegment) return false;
    }

    if (otherPathSegments.length > 0) {
      matchedWith = other.uriPath;
      _params = ownPathSegments;
      _paramIndices = _foldParams(otherPathSegments);
    } else {
      matchedWith = uriPath;
      _params = otherPathSegments;

      _paramIndices = _foldParams(ownPathSegments);
    }

    return true;
  }

  Map<String, int> _foldParams(List<String> segments) {
    return segments.asMap().entries.fold({}, (map, entry) {
      map[entry.value.replaceFirst(':', '')] = entry.key;
      return map;
    });
  }

  @override
  int get hashCode => this.httpMethod.hashCode + this.uriPath.hashCode;
}

class GET extends Route {
  final String pattern;
  GET(this.pattern) : super(HttpMethod.GET, pattern);
}

class POST extends Route {
  final String pattern;
  POST(this.pattern) : super(HttpMethod.POST, pattern);
}

class PUT extends Route {
  final String pattern;
  PUT(this.pattern) : super(HttpMethod.PUT, pattern);
}

class DELETE extends Route {
  final String pattern;
  DELETE(this.pattern) : super(HttpMethod.DELETE, pattern);
}

class PATCH extends Route {
  final String pattern;
  PATCH(this.pattern) : super(HttpMethod.PATCH, pattern);
}

class OPTIONS extends Route {
  final String pattern;
  OPTIONS(this.pattern) : super(HttpMethod.OPTIONS, pattern);
}

class HEAD extends Route {
  final String pattern;
  HEAD(this.pattern) : super(HttpMethod.HEAD, pattern);
}

extension HttpRoute on HttpRequest {
  Route route() {
    return Route(
      HttpMethod.fromString(this.method),
      this.uri.path,
      this,
    );
  }
}

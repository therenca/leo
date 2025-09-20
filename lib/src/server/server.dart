import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';

import 'batch.dart';
import 'match_uri.dart';
import 'http_route.dart';
import 'response.dart';
import 'package:leo/leo.dart';
import 'http_body_file_upload.dart';
import 'http_multipart_form_data.dart';
import 'package:mime/mime.dart' as mime;

abstract class Server {
  late int port;
  String ip = 'localhost';

  String? logFile;
  Color color = Color.cyann;
  String header = 'server';
  bool verbose = false;

  late Map<String, RequestHandler> routes;

  // let's have a global middleware utility option
  // that asserts for expected values on all uris/requests before proceeding
  Middleware? middleware;

  String? cert;
  String? privateKey;

  bool https = false;
  bool shared = false;
  late HttpServer server;

  Future<HttpServer> start() async {
    if (verbose) {
      await pretifyOutput(
          '[${DateTime.now().toIso8601String()}][$header] starting ...',
          color: color);
    }

    if (https) {
      assert(cert != null);
      assert(privateKey != null);
      SecurityContext security = SecurityContext();
      security.useCertificateChain(cert!);
      security.usePrivateKey(privateKey!);
      server = await HttpServer.bindSecure(ip, port, security);
    } else {
      server = await HttpServer.bind(ip, port, shared: shared);
    }
    server
        .listen((HttpRequest request) async => await _handleRequests(request));
    return server;
  }

  Future<void> _handleRequests(HttpRequest request) async {
    Batch? batch;
    var clientData;
    bool isWebSocket = false;
    var uri = request.uri.path;
    var method = request.method;
    Route route = request.route();
    Response? response;

    var contentType = request.headers.contentType;
    var mimeType =
        contentType == null ? 'no mimetype set' : contentType.mimeType;

    var isGloblMiddlewareSuccessful = true; // by default
    switch (mimeType) {
      case 'application/json':
        {
          var jsonString = await utf8.decoder.bind(request).join();
          clientData = jsonDecode(jsonString);

          break;
        }

      case 'application/x-www-form-urlencoded':
        {
          var body = await utf8.decoder.bind(request).join();
          var map = Uri.splitQueryString(body);
          clientData = {};
          for (var key in map.keys) {
            clientData[key] = map[key];
          }
          break;
        }

      case 'multipart/form-data':
        {
          var values = await mime.MimeMultipartTransformer(
                  contentType!.parameters['boundary']!)
              .bind(request)
              .map((part) =>
                  HttpMultipartFormData.parse(part, defaultEncoding: utf8))
              .map((multipart) async {
            dynamic data;
            if (multipart.isText) {
              var buffer = await multipart.fold<StringBuffer>(
                  StringBuffer(), (b, s) => b..write(s));
              data = buffer.toString();
            } else {
              // ignore: deprecated_export_use
              var buffer = await multipart.fold<BytesBuilder>(
                  // ignore: deprecated_export_use
                  BytesBuilder(),
                  (b, d) => b..add(d as List<int>));
              data = buffer.takeBytes();
            }
            var filename = multipart.contentDisposition.parameters['filename'];
            if (filename != null) {
              data = HttpBodyFileUpload(multipart.contentType, filename, data);
            }
            return [multipart.contentDisposition.parameters['name'], data];
          }).toList();
          var parts = await Future.wait(values);
          clientData = <String, dynamic>{};
          for (var part in parts) {
            clientData[part[0] as String] =
                part[1]; // Override existing entries.
          }
          break;
        }

      default:
        {
          break;
        }
    }

    if (verbose) {
      await Log(uri, method,
          header: header,
          request: request,
          mimetype: mimeType,
          data: clientData,
          logFile: logFile);
    }

    middleware?.route = route;
    middleware?.data = clientData;
    isGloblMiddlewareSuccessful = await middleware?.run() ?? true;
    if (isGloblMiddlewareSuccessful) {
      var matchedUri = MatchUri.match(routes, route);
      if (matchedUri != null) {
        var handler = routes[matchedUri];
        isWebSocket = _checkForWebSocket(handler);
        if (isWebSocket == false) {
          batch = Batch(
              uri: matchedUri,
              route: route,
              routes: routes,
              method: method,
              data: clientData,
              verbose: verbose);
              response = await batch.run();
        } else {
          // WebSocket handling remains the same
          callback([_]) async {
            var _handler = handler as Ws;
            WebSocket ws = await WebSocketTransformer.upgrade(request);
            ws.pingInterval = Duration(seconds: _handler.pingInterval);
            await _handler.onOpen(ws);
          }

          await tryCatch(callback,
              verbose: verbose, tag: 'upgrading to ws');
        }
      } else {
        if (verbose) {
          pretifyOutput('[$header][${route.httpMethod.value}] define request handler for ${route.uriPath}',
              color: Color.red);
        }
      }
    }

    if (isWebSocket == false) {
      if (response != null) {
        // Use the Response object to write to the HTTP response
        await response.writeTo(request.response);
      } else {
        // Handle middleware failures or missing handlers
        Response errorResponse;
        if (isGloblMiddlewareSuccessful == false) {
          if (verbose) {
            await pretifyOutput(
                '[MAIN MIDDLEWARE | ${middleware!.name} | ${route.uriPath}] check failed',
                color: Color.red);
          }
          errorResponse = Response.forbidden();
        } else if ((batch?.isMiddlewarePerRequestSuccessful ?? false) == false) {
          errorResponse = Response.forbidden();
        } else {
          // No handler found
          errorResponse = Response.notFound();
        }
        await errorResponse.writeTo(request.response);
      }
    }
  }

  bool _checkForWebSocket(RequestHandler? handler) => handler is Ws;
}

abstract class RequestHandler {
  List<Middleware>? middleware;
  
  // Main handler method that delegates to specific HTTP method handlers
  Future<Response> handle(Route route, [dynamic data]) async {
    switch (route.httpMethod) {
      case HttpMethod.GET:
        return await get(route, data);
      case HttpMethod.POST:
        return await post(route, data);
      case HttpMethod.PUT:
        return await put(route, data);
      case HttpMethod.DELETE:
        return await delete(route, data);
      case HttpMethod.PATCH:
        return await patch(route, data);
      case HttpMethod.OPTIONS:
        return await options(route, data);
      case HttpMethod.HEAD:
        return await head(route, data);
    }
  }
  
  // HTTP method handlers
  Future<Response> get(Route route, [dynamic data]) async => Response.status(405);
  Future<Response> post(Route route, [dynamic data]) async => Response.status(405);
  Future<Response> put(Route route, [dynamic data]) async => Response.status(405);
  Future<Response> delete(Route route, [dynamic data]) async => Response.status(405);
  Future<Response> patch(Route route, [dynamic data]) async => Response.status(405);
  Future<Response> options(Route route, [dynamic data]) async => Response.status(405);
  Future<Response> head(Route route, [dynamic data]) async => Response.status(405);
}

abstract class Middleware {
  String? uri;
  dynamic data;
  Route? route;
  String name = 'Middleware (Set unique name for middleware)';

  Future<bool> run();
}

// we are extending RequestHandler to promote uniformity when structuring the server
abstract class Ws extends RequestHandler {
  ///in seconds
  int pingInterval = 10;
  Future<void> onOpen(WebSocket socket);
  Future<void> onClose(WebSocket socket);
  Future<void> onMessage(WebSocket socket, data);
  Future<void> onError(WebSocket socket, error);
}

class WsClients {
  String name;
  bool? verbose;
  
  WsClients({required this.name, this.verbose = false});
  
  // Use Set for better performance on nameless clients
  final Set<WebSocket> _namelessClients = <WebSocket>{};
  final Map<String, WebSocket> _namedClients = <String, WebSocket>{};
  // Reverse lookup map for O(1) named client removal
  final Map<WebSocket, String> _socketToId = <WebSocket, String>{};

  // Getters for external access
  Set<WebSocket> get namelessClients => Set.unmodifiable(_namelessClients);
  Map<String, WebSocket> get namedClients => Map.unmodifiable(_namedClients);
  
  // Client counts
  int get totalClients => _namelessClients.length + _namedClients.length;
  int get namedClientCount => _namedClients.length;
  int get namelessClientCount => _namelessClients.length;
  
  // Get all connected client IDs
  List<String> get connectedIds => _namedClients.keys.toList();

  /// Get a named client by ID
  WebSocket? getNamedClient(String id) => _namedClients[id];
  
  /// Check if a socket exists in nameless clients
  bool hasNamelessClient(WebSocket socket) => _namelessClients.contains(socket);
  
  /// Get the ID of a named client by socket
  String? getClientId(WebSocket socket) => _socketToId[socket];

  /// Add a nameless client
  void addNamelessClient(WebSocket socket) {
    if (_namelessClients.add(socket)) {
      if (verbose ?? false) {
        pretifyOutput('[ws] socket added (total: $totalClients)', color: Color.magenta);
      }
    }
  }

  /// Remove a nameless client
  bool removeNamelessClient(WebSocket socket) {
    final removed = _namelessClients.remove(socket);
    if (removed && verbose == true) {
      pretifyOutput('[ws] nameless socket removed', color: Color.yellow);
    }
    return removed;
  }

  /// Mark a client with an ID (move from nameless to named)
  void markClient(String id, WebSocket socket) {
    // Remove from nameless if present
    _namelessClients.remove(socket);
    
    // Remove existing mapping if socket was already named
    final oldId = _socketToId[socket];
    if (oldId != null) {
      _namedClients.remove(oldId);
    }
    
    // Remove existing socket if ID was already used
    final oldSocket = _namedClients[id];
    if (oldSocket != null) {
      _socketToId.remove(oldSocket);
    }
    
    // Add new mappings
    _namedClients[id] = socket;
    _socketToId[socket] = id;
    
    if (verbose ?? false) {
      pretifyOutput('[ws] socket marked as "$id" (total: $totalClients)', color: Color.green);
    }
  }

  /// Remove a named client by socket (O(1) lookup)
  bool removeNamedClient(WebSocket socket) {
    final id = _socketToId.remove(socket);
    if (id != null) {
      _namedClients.remove(id);
      if (verbose == true) {
        pretifyOutput('[ws] named client "$id" removed', color: Color.yellow);
      }
      return true;
    }
    return false;
  }
  
  /// Remove a named client by ID
  bool removeById(String id) {
    final socket = _namedClients.remove(id);
    if (socket != null) {
      _socketToId.remove(socket);
      if (verbose == true) {
        pretifyOutput('[ws] client "$id" removed', color: Color.yellow);
      }
      return true;
    }
    return false;
  }

  /// Remove a client (named or nameless)
  bool remove(WebSocket socket) {
    final removedNamed = removeNamedClient(socket);
    final removedNameless = removeNamelessClient(socket);
    
    if (removedNamed || removedNameless) {
      if (verbose ?? false) {
        pretifyOutput('[ws] socket removed (total: $totalClients)', color: Color.red);
      }
      return true;
    }
    return false;
  }
  
  /// Broadcast message to all clients
  void broadcast(String message, {String? excludeId}) {
    // Broadcast to nameless clients
    for (final socket in _namelessClients) {
      _safeSend(socket, message);
    }
    
    // Broadcast to named clients
    for (final entry in _namedClients.entries) {
      if (excludeId == null || entry.key != excludeId) {
        _safeSend(entry.value, message);
      }
    }
  }
  
  /// Broadcast message to named clients only
  void broadcastToNamed(String message, {String? excludeId}) {
    for (final entry in _namedClients.entries) {
      if (excludeId == null || entry.key != excludeId) {
        _safeSend(entry.value, message);
      }
    }
  }
  
  /// Send message to specific named client
  bool sendToClient(String id, String message) {
    final socket = _namedClients[id];
    if (socket != null) {
      _safeSend(socket, message);
      return true;
    }
    return false;
  }
  
  /// Clear all clients
  void clear() {
    final count = totalClients;
    _namelessClients.clear();
    _namedClients.clear();
    _socketToId.clear();
    
    if (verbose ?? false) {
      pretifyOutput('[ws] cleared $count clients', color: Color.red);
    }
  }
  
  /// Safe send that handles closed sockets
  void _safeSend(WebSocket socket, String message) {
    try {
      if (socket.readyState == WebSocket.open) {
        socket.add(message);
      } else {
        // Socket is closed, remove it
        remove(socket);
      }
    } catch (e) {
      // Error sending, remove the socket
      remove(socket);
      if (verbose ?? false) {
        pretifyOutput('[ws] removed dead socket: $e', color: Color.red);
      }
    }
  }
}

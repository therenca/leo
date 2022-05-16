import 'dart:io';
import 'dart:convert';

import 'batch.dart';
import 'match_uri.dart';
import 'http_route.dart';
import 'package:leo/leo.dart';
import 'http_body_file_upload.dart';
import 'http_multipart_form_data.dart';
import 'package:mime/mime.dart' as mime;

abstract class Server {

	late int port;
	String ip = 'localhost';

	String? logFile;
	String color = 'cyan';
	String header = 'server';

	late Map<String, RequestHandler> routes;

	// let's have a global middleware utility option
	// that asserts for expected values on all uris/requests before proceeding
	Middleware? middleware;

	String? cert;
	String? privateKey;

	bool https = false;

	Future<void> start() async {
		await pretifyOutput('[$header] starting ...', color: color);
		HttpServer server;

		if(https){
			assert(cert != null);
			assert(privateKey != null);
			SecurityContext security = SecurityContext();
			security.useCertificateChain(cert!);
			security.usePrivateKey(privateKey!);
			server = await HttpServer.bindSecure(
				ip,
				port,
				security
			);

		} else {
			server = await HttpServer.bind(
				ip,
				port,
			);
		}

		await for (HttpRequest request in server){
			await _handleRequests(request);
		}
	}

	Future<void> _handleRequests(HttpRequest request) async {

		Batch? batch;
		var clientData;
		var uri = request.uri.path;
		var method = request.method;
		Route route = request.route();
		Map<String, dynamic>? backToClient;

		var contentType = request.headers.contentType;
		var mimeType = contentType == null ? 'not set' : contentType.mimeType;

		var isGloblMiddlewareSuccessful = true; // by default
		switch(mimeType){
			case 'application/json': {
				var jsonString = await utf8.decoder.bind(request).join();
				clientData = jsonDecode(jsonString);

				break;
			}

			case 'application/x-www-form-urlencoded': {
				var body = await utf8.decoder.bind(request).join();
				var map = Uri.splitQueryString(body);
				clientData = {};
				for (var key in map.keys) {
					clientData[key] = map[key];
				}
				break;
			}

			case 'multipart/form-data': {
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
						var buffer = await multipart.fold<BytesBuilder>(
								BytesBuilder(), (b, d) => b..add(d as List<int>));
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
					clientData[part[0] as String] = part[1]; // Override existing entries.
				}
				break;
			}

			default: {
				break;
			}
		}

		await Log(
			uri, method, header: header, request: request, mimetype: mimeType, data: clientData, logFile: logFile);


		if(middleware != null){
			middleware!.route = route;
			middleware!.data = clientData;
			isGloblMiddlewareSuccessful = await middleware!.run();
		}

		if(isGloblMiddlewareSuccessful){
			switch(method){
				case 'GET': {
					var uri = MatchUri.GET(routes, route);
					if(uri != null){
						batch = Batch(
							uri: uri,
							route: route,
							routes: routes,
							method: method,
							data: clientData,
						);
						backToClient = await batch.run();
					} else {
						pretifyOutput('[$header][GET] define request handler for $uri');
					}

					break;
				}

				case 'POST': {
					var uri = MatchUri.POST(routes, route);
					if(uri != null){
						batch = Batch(
							uri: uri,
							route: route,
							routes: routes,
							method: method,
							data: clientData,
						);
						backToClient = await batch.run();
					} else {
						pretifyOutput('[$header][POST] define request handler for $uri');
					}

					break;
				}
			}
		}

		if(backToClient != null){
			request.response.headers.contentType = ContentType.json;
			request.response.write(jsonEncode(backToClient));
		} else {
			if(isGloblMiddlewareSuccessful == false || 
			(batch?.isMiddlewarePerRequestSuccessful ?? false) == false){
				if(!isGloblMiddlewareSuccessful){
					await pretifyOutput(
						'[MAIN MIDDLEWARE | ${middleware!.name} | ${batch!.uri}] check failed', color: 'red');
				}
				request.response.statusCode = HttpStatus.forbidden;
			}
		}
		await request.response.close();
	}
}

abstract class RequestHandler {
	List<Middleware>? middleware;
	Future<Map<String, dynamic>> get(Route route, [dynamic data]);
	Future<Map<String, dynamic>> post(Route route, [dynamic data]);
}

abstract class Middleware {
	String? uri;
	Route? route;
	dynamic data;
	String name = 'Middleware (Set unique name for middleware)';

	Future<bool> run();
}
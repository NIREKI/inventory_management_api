import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';

import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes.
var env = DotEnv(includePlatformEnvironment: true)..load();

PostgreSQLConnection connection = PostgreSQLConnection(
    env['PGHOST'].toString(), 5432, "inventoryDB",
    username: env['PGUSER'], password: env['PGPASSWORD'], useSSL: true);
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..get('/test', _testResponse);

Response _rootHandler(Request req) {
  return Response.ok(Response.ok(''));
}

Future<Response> _testResponse(Request req) async {
  List<Map<String, Map<String, dynamic>>> results =
      await connection.mappedResultsQuery("SELECT * FROM contract");
  Map<String, String> headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST,GET,DELETE,PUT,OPTIONS"
  };
  return Response.ok(json.encode(results), headers: headers);
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  await connection.open();
  print(connection.host);
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}

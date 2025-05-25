import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import '../lib/game_api_service.dart';

void main(List<String> args) async {
  print('Initializing Game Backend Server...');
  
  // Use any available port
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  
  // Create service with proper initialization
  print('Setting up game service...');
  final gameService = GameApiService();
  
  // Initialize a new game by default to ensure we have a valid game state
  try {
    print('Setting up initial game state...');
    gameService.initializeGame();
    print('Game state initialized successfully');
  } catch (e) {
    print('Warning: Failed to initialize game state: $e');
    print('Some API methods may not work until a new game is started');
    print('Error details: $e');
  }
  
  // Configure routes
  final router = Router()
    ..mount('/api', gameService.router)
    // Serve dashboard
    ..get('/', _serveIndex)
    ..get('/dashboard', _serveIndex)
    // Serve static files
    ..get('/public/<file|.*>', _serveStatic);
  
  // Create a handler for the server with middleware
  final handler = Pipeline()
      .addMiddleware(logRequests()) // Log requests
      .addMiddleware(_corsHeaders()) // Handle CORS
      .addHandler(router);

  // Start server
  print('Starting HTTP server on port $port...');
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  print('Game Backend Server started at: http://${server.address.host}:${server.port}');
  print('Dashboard: http://localhost:$port/dashboard');
  print('API: http://localhost:$port/api/status');
}

// CORS middleware
Middleware _corsHeaders() {
  return createMiddleware(
    responseHandler: (response) {
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',
        'Access-Control-Allow-Headers': 'Origin, Content-Type',
      });
    },
    requestHandler: (request) {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',
          'Access-Control-Allow-Headers': 'Origin, Content-Type',
        });
      }
      return null;
    },
  );
}

// Handle index/dashboard requests
Response _serveIndex(Request request) {
  final indexFile = File('public/dashboard.html');
  if (indexFile.existsSync()) {
    return Response.ok(
      indexFile.readAsBytesSync(),
      headers: {'Content-Type': 'text/html'},
    );
  } else {
    return Response.ok(
      '<html><body><h1>Game API Server</h1>'
      '<p>Dashboard not found. API is available at <a href="/api/status">/api/status</a>.</p></body></html>',
      headers: {'Content-Type': 'text/html'},
    );
  }
}

// Serve static files from public directory
Response _serveStatic(Request request, String file) {
  final staticFile = File('public/$file');
  if (staticFile.existsSync()) {
    String contentType = 'text/plain';
    if (file.endsWith('.html')) contentType = 'text/html';
    if (file.endsWith('.css')) contentType = 'text/css';
    if (file.endsWith('.js')) contentType = 'application/javascript';
    if (file.endsWith('.json')) contentType = 'application/json';
    if (file.endsWith('.png')) contentType = 'image/png';
    if (file.endsWith('.jpg') || file.endsWith('.jpeg')) contentType = 'image/jpeg';
    
    return Response.ok(
      staticFile.readAsBytesSync(),
      headers: {'Content-Type': contentType},
    );
  } else {
    return Response.notFound('File not found: $file');
  }
}

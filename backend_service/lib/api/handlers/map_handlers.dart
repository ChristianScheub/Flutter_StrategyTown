import 'package:riverpod/riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:shelf/shelf.dart';
import '../api_responses.dart';

/// Handles map and tile-related API endpoints
class MapHandlers {
  final ProviderContainer container;
  
  MapHandlers(this.container);
  
  /// Access the terminal game interface through the provider
  TerminalGameInterface get gameInterface => container.read(terminalGameInterfaceProvider);
  
  /// Get tile information
  Response getTileInfo(Request request, String xStr, String yStr) {
    try {
      final x = int.parse(xStr);
      final y = int.parse(yStr);
      final tileInfo = gameInterface.getTileInfo(x, y);
      return ApiResponseHelper.successResponse('Tile info retrieved', {'tileInfo': tileInfo});
    } catch (e) {
      return ApiResponseHelper.errorResponse('Invalid coordinates: $e');
    }
  }
  
  /// Get tile resources
  Response getTileResources(Request request, String xStr, String yStr) {
    try {
      final x = int.parse(xStr);
      final y = int.parse(yStr);
      final resources = gameInterface.getTileResources(x, y);
      return ApiResponseHelper.successResponse('Tile resources retrieved', {'resources': resources});
    } catch (e) {
      return ApiResponseHelper.errorResponse('Invalid coordinates: $e');
    }
  }
  
  /// Get area map around center point
  Response getAreaMap(Request request, String centerXStr, String centerYStr, String radiusStr) {
    try {
      final centerX = int.parse(centerXStr);
      final centerY = int.parse(centerYStr);
      final radius = int.parse(radiusStr);
      final areaMap = gameInterface.getAreaMap(centerX, centerY, radius: radius);
      return ApiResponseHelper.successResponse('Area map retrieved', {'areaMap': areaMap});
    } catch (e) {
      return ApiResponseHelper.errorResponse('Invalid parameters: $e');
    }
  }
  
  /// Select a tile
  Response selectTile(Request request, String xStr, String yStr) {
    try {
      final x = int.parse(xStr);
      final y = int.parse(yStr);
      final result = gameInterface.selectTile(x, y);
      return ApiResponseHelper.successResponse(result);
    } catch (e) {
      return ApiResponseHelper.errorResponse('Invalid coordinates: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_city_frontend/widgets/building_widget.dart';
import 'package:flutter_city_frontend/widgets/tile_widget.dart';
import 'package:flutter_city_frontend/widgets/unit_widget.dart';
import 'package:game_core/game_core.dart';

// Interface to access GameMap functionality
class GameMapController {
  void Function(Position)? jumpToPosition;
}

class GameMap extends StatefulWidget {
  final TileMap map;
  final List<Unit> units;
  final List<Building> buildings;
  final Position cameraPosition;
  final String? selectedUnitId;
  final String? selectedBuildingId;
  final Position? selectedTilePosition;
  final List<Position> validMovePositions;
  final Function(Position) onTileTap;
  final Function(String) onUnitTap;
  final Function(String) onBuildingTap;
  final GameMapController? controller; // Controller for external access
  final List<Unit>? enemyUnits; // Feindliche Einheiten
  final List<Building>? enemyBuildings; // Feindliche Gebäude

  const GameMap({
    super.key,
    this.controller,
    required this.map,
    required this.units,
    required this.buildings,
    required this.cameraPosition,
    this.selectedUnitId,
    this.selectedBuildingId,
    this.selectedTilePosition,
    this.validMovePositions = const [], // Standard-Wert ist eine leere Liste
    required this.onTileTap,
    required this.onUnitTap,
    required this.onBuildingTap,
    this.enemyUnits, // Feindliche Einheiten (optional)
    this.enemyBuildings, // Feindliche Gebäude (optional)
  });

  @override
  State<GameMap> createState() => _GameMapState();
}

class _GameMapState extends State<GameMap> {
  // View settings
  static const tileSize = 60.0;
  // Radius ist jetzt dynamisch basierend auf der Bildschirmgröße
  
  // Gesture control
  late Offset _lastPanPosition;
  late Position _mapPosition;
  double _scale = 1.0;
  
  @override
  void initState() {
    super.initState();
    _mapPosition = widget.cameraPosition;
    
    // Register jumpToPosition method with the controller
    if (widget.controller != null) {
      widget.controller!.jumpToPosition = jumpToPosition;
    }
  }
  
  @override
  void didUpdateWidget(GameMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraPosition != widget.cameraPosition) {
      _mapPosition = widget.cameraPosition;
    }
    
    // Update controller if it changed
    if (widget.controller != oldWidget.controller && widget.controller != null) {
      widget.controller!.jumpToPosition = jumpToPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return GestureDetector(
      onScaleStart: (details) {
        _lastPanPosition = details.focalPoint;
      },
      onScaleUpdate: (details) {
        final delta = details.focalPoint - _lastPanPosition;
        _lastPanPosition = details.focalPoint;
        
        setState(() {
          // Handle zooming (sanfteres Verhalten)
          if (details.scale != 1.0) {
            final newScale = (_scale * details.scale).clamp(0.5, 2.5);
            // Verhindern von zu schnellen Zoom-Änderungen
            _scale = newScale;
          }
          
          // Handle panning - in einer unendlichen Karte gibt es keine Grenzen
          final dx = delta.dx / (tileSize * _scale);
          final dy = delta.dy / (tileSize * _scale);
          
          // Bewegung ist flüssiger wenn wir Fließkommazahlen verwenden anstatt zu runden
          _mapPosition = Position(
            x: _mapPosition.x - dx.round(),
            y: _mapPosition.y - dy.round(),
          );
        });
      },
      child: Stack(
        children: [
          // Background
          Container(color: Colors.black),
          
          // Render the visible tiles
          ..._renderVisibleTiles(screenSize),
          
          // Render buildings first (will appear below units)
          ..._renderBuildings(),
          
          // Render units on top so they're always selectable
          ..._renderUnits(),
          
          // Debug-Anzeige für Koordinaten
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Position: (${_mapPosition.x}, ${_mapPosition.y})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          
          // Grid overlay for debugging
          // _buildGridOverlay(screenSize),
        ],
      ),
    );
  }
  
  // Check if multiple selectable objects exist at a position
  List<Map<String, dynamic>> _getSelectableObjectsAt(Position position) {
    final objects = <Map<String, dynamic>>[];
    
    // Check for buildings
    for (final building in widget.buildings) {
      if (building.position == position) {
        objects.add({
          'type': 'building',
          'id': building.id,
          'name': building.name,
          'object': building,
        });
      }
    }
    
    // Check for units
    for (final unit in widget.units) {
      if (unit.position == position) {
        objects.add({
          'type': 'unit',
          'id': unit.id,
          'name': unit.name,
          'object': unit,
        });
      }
    }
    
    return objects;
  }
  
  // Show selection dialog when multiple objects are at the same position
  void _showSelectionDialog(BuildContext context, Position position) {
    final objects = _getSelectableObjectsAt(position);
    
    if (objects.isEmpty) {
      // If no objects, just select the tile
      widget.onTileTap(position);
      return;
    }
    
    if (objects.length == 1) {
      // If only one object, select it directly
      final object = objects.first;
      if (object['type'] == 'building') {
        widget.onBuildingTap(object['id']);
      } else if (object['type'] == 'unit') {
        widget.onUnitTap(object['id']);
      }
      return;
    }
    
    // Multiple objects - show selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auswahl'),
        content: SizedBox(
          width: double.minPositive,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: objects.length,
            itemBuilder: (context, index) {
              final object = objects[index];
              final icon = object['type'] == 'building' 
                  ? Icons.home_work 
                  : Icons.person;
                  
              return ListTile(
                leading: Icon(icon),
                title: Text(object['name']),
                subtitle: Text(object['type'] == 'building' ? 'Gebäude' : 'Einheit'),
                onTap: () {
                  Navigator.of(context).pop();
                  if (object['type'] == 'building') {
                    widget.onBuildingTap(object['id']);
                  } else if (object['type'] == 'unit') {
                    widget.onUnitTap(object['id']);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Just select the tile instead
              widget.onTileTap(position);
            }, 
            child: const Text('Kachel auswählen'),
          ),
        ],
      ),
    );
  }

  List<Widget> _renderVisibleTiles(Size screenSize) {
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    final effectiveTileSize = tileSize * _scale;
    
    final visibleTiles = <Widget>[];
    
    // Determine visible area based on screen size and tile size
    final horizontalTiles = (screenSize.width / effectiveTileSize).ceil() + 2;
    final verticalTiles = (screenSize.height / effectiveTileSize).ceil() + 2;
    
    final minX = _mapPosition.x - horizontalTiles ~/ 2;
    final maxX = _mapPosition.x + horizontalTiles ~/ 2;
    final minY = _mapPosition.y - verticalTiles ~/ 2;
    final maxY = _mapPosition.y + verticalTiles ~/ 2;
    
    // Stellen Sie sicher, dass der sichtbare Bereich und ein Puffer um ihn herum existiert
    widget.map.ensureAreaExists(minX - 5, minY - 5, maxX + 5, maxY + 5);
    
    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        final position = Position(x: x, y: y);
        final tile = widget.map.getTile(position);
        
        // Calculate screen position
        final screenX = centerX + (x - _mapPosition.x) * effectiveTileSize;
        final screenY = centerY + (y - _mapPosition.y) * effectiveTileSize;
        
        // Check if this tile is selected
        final isSelected = widget.selectedTilePosition == position;
        
        // Prüfen, ob diese Position ein gültiges Bewegungsziel ist
        final isValidMoveTarget = widget.validMovePositions.contains(position);
        
        visibleTiles.add(
          Positioned(
            left: screenX - effectiveTileSize / 2,
            top: screenY - effectiveTileSize / 2,
            child: GestureDetector(
              onTap: () {
                // Check if there are multiple objects at this position
                final objectsAtPosition = _getSelectableObjectsAt(position);
                if (objectsAtPosition.length > 1) {
                  _showSelectionDialog(context, position);
                } else {
                  widget.onTileTap(position);
                }
              },
              child: TileWidget(
                tile: tile.copyWith(isSelected: isSelected),
                size: effectiveTileSize,
                isValidMoveTarget: isValidMoveTarget,  // Die neue Eigenschaft übergeben
              ),
            ),
          ),
        );
      }
    }
    
    return visibleTiles;
  }
  
  List<Widget> _renderUnits() {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    final effectiveTileSize = tileSize * _scale;
    
    final visibleUnits = <Widget>[];
    
    // Rendere Spielereinheiten
    for (final unit in widget.units) {
      // Calculate screen position
      final screenX = centerX + 
          (unit.position.x - _mapPosition.x) * effectiveTileSize;
      final screenY = centerY + 
          (unit.position.y - _mapPosition.y) * effectiveTileSize;
      
      // Check if this unit is selected
      final isSelected = widget.selectedUnitId == unit.id;
      
      visibleUnits.add(
        Positioned(
          left: screenX - effectiveTileSize / 2,
          top: screenY - effectiveTileSize / 2,
          child: GestureDetector(
            onTap: () {
              // Always check for multiple objects at this position first
              final objectsAtPosition = _getSelectableObjectsAt(unit.position);
              if (objectsAtPosition.length > 1) {
                _showSelectionDialog(context, unit.position);
              } else {
                widget.onUnitTap(unit.id);
              }
            },
            child: UnitWidget(
              unit: isSelected 
                  ? unit.copyWith(isSelected: true) 
                  : unit,
              size: effectiveTileSize,
              isEnemy: false,
            ),
          ),
        ),
      );
    }
    
    // Rendere feindliche Einheiten
    if (widget.enemyUnits != null) {
      for (final enemyUnit in widget.enemyUnits!) {
        // Calculate screen position
        final screenX = centerX + 
            (enemyUnit.position.x - _mapPosition.x) * effectiveTileSize;
        final screenY = centerY + 
            (enemyUnit.position.y - _mapPosition.y) * effectiveTileSize;
        
        visibleUnits.add(
          Positioned(
            left: screenX - effectiveTileSize / 2,
            top: screenY - effectiveTileSize / 2,
            child: GestureDetector(
              onTap: () {
                // Klick auf eine feindliche Einheit wählt die Kachel aus
                widget.onTileTap(enemyUnit.position);
              },
              child: Stack(
                children: [
                  UnitWidget(
                    unit: enemyUnit,
                    size: effectiveTileSize,
                    isEnemy: true, // Markiere als Feind
                  ),
                  // Add attack indicator if player has selected a unit that can attack this enemy
                  if (widget.selectedUnitId != null && 
                      widget.units.any((u) => u.id == widget.selectedUnitId &&
                          u is CombatCapable &&
                          (u as CombatCapable).canAttackAt(enemyUnit.position)))
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(effectiveTileSize * 0.5),
                          color: Colors.red.withOpacity(0.3),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.gps_fixed,  // Using a crosshair icon
                            color: Colors.white,
                            size: effectiveTileSize * 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }
    
    return visibleUnits;
  }
  
  List<Widget> _renderBuildings() {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    final effectiveTileSize = tileSize * _scale;
    
    final visibleBuildings = <Widget>[];
    
    // Rendere Spielergebäude
    for (final building in widget.buildings) {
      // Calculate screen position
      final screenX = centerX + 
          (building.position.x - _mapPosition.x) * effectiveTileSize;
      final screenY = centerY + 
          (building.position.y - _mapPosition.y) * effectiveTileSize;
      
      // Check if this building is selected
      final isSelected = widget.selectedBuildingId == building.id;
      
      visibleBuildings.add(
        Positioned(
          left: screenX - effectiveTileSize / 2,
          top: screenY - effectiveTileSize / 2,
          child: GestureDetector(
            onTap: () {
              print('Building tapped: ${building.id} at position (${building.position.x}, ${building.position.y})');
              // Check if there are multiple objects at this position
              final objectsAtPosition = _getSelectableObjectsAt(building.position);
              print('Objects at position: ${objectsAtPosition.length}');
              for (final obj in objectsAtPosition) {
                print('  - ${obj['type']}: ${obj['name']} (ID: ${obj['id']})');
              }
              // Always handle collision detection the same way for consistency
              if (objectsAtPosition.length > 1) {
                print('Showing selection dialog for multiple objects');
                _showSelectionDialog(context, building.position);
              } else {
                print('Calling onBuildingTap with building ID: ${building.id}');
                widget.onBuildingTap(building.id);
              }
            },
            child: BuildingWidget(
              building: building,
              isSelected: isSelected,
              size: effectiveTileSize,
              isEnemy: false,
            ),
          ),
        ),
      );
    }
    
    // Rendere feindliche Gebäude
    if (widget.enemyBuildings != null) {
      for (final enemyBuilding in widget.enemyBuildings!) {
        // Calculate screen position
        final screenX = centerX + 
            (enemyBuilding.position.x - _mapPosition.x) * effectiveTileSize;
        final screenY = centerY + 
            (enemyBuilding.position.y - _mapPosition.y) * effectiveTileSize;
        
        visibleBuildings.add(
          Positioned(
            left: screenX - effectiveTileSize / 2,
            top: screenY - effectiveTileSize / 2,
            child: GestureDetector(
              onTap: () {
                // Klick auf ein feindliches Gebäude wählt die Kachel aus
                widget.onTileTap(enemyBuilding.position);
              },
              child: Stack(
                children: [
                  BuildingWidget(
                    building: enemyBuilding,
                    isSelected: false,
                    size: effectiveTileSize,
                    isEnemy: true, // Markiere als Feind
                  ),
                  // Add attack indicator if player has selected a unit that can attack this enemy
                  if (widget.selectedUnitId != null && 
                      widget.units.any((u) => u.id == widget.selectedUnitId &&
                          u is CombatCapable &&
                          (u as CombatCapable).canAttackAt(enemyBuilding.position)))
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(effectiveTileSize * 0.15),
                          color: Colors.red.withOpacity(0.3),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.gps_fixed,
                            color: Colors.white,
                            size: effectiveTileSize * 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }
    
    return visibleBuildings;
  }
  
  // Diese Methode kann verwendet werden, um zu einer bestimmten Position zu springen
  void jumpToPosition(Position position) {
    setState(() {
      _mapPosition = position;
    });
  }
  
  // Debugging helper method - uncomment in the build method to see grid overlay
  /*Widget _buildGridOverlay(Size screenSize) {
    return CustomPaint(
      size: screenSize,
      painter: GridPainter(
        cameraPosition: _mapPosition,
        tileSize: tileSize * _scale,
        screenCenter: Offset(screenSize.width / 2, screenSize.height / 2),
      ),
    );
  }*/
}

class GridPainter extends CustomPainter {
  final Position cameraPosition;
  final double tileSize;
  final Offset screenCenter;
  
  GridPainter({
    required this.cameraPosition,
    required this.tileSize,
    required this.screenCenter,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Determine how many grid lines to draw based on screen size
    final horizontalLines = (size.height / tileSize).ceil() + 2;
    final verticalLines = (size.width / tileSize).ceil() + 2;
    
    // Draw horizontal lines
    for (int i = -horizontalLines ~/ 2; i <= horizontalLines ~/ 2; i++) {
      final y = screenCenter.dy + i * tileSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw vertical lines
    for (int i = -verticalLines ~/ 2; i <= verticalLines ~/ 2; i++) {
      final x = screenCenter.dx + i * tileSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
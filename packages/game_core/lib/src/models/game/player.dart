import 'package:equatable/equatable.dart';
import '../resource/resources_collection.dart';

/// Enum für Spielertypen
enum PlayerType {
  human,
  ai,
}

/// Repräsentiert einen Spieler im Spiel (menschlich oder KI)
class Player extends Equatable {
  final String id;
  final String name;
  final PlayerType type;
  final ResourcesCollection resources;
  final int points;
  final bool isActive;
  final String? faction; // Kann später für verschiedene Fraktionen verwendet werden
  final Map<String, dynamic> metadata; // Für zusätzliche spielerspezifische Daten

  const Player({
    required this.id,
    required this.name,
    required this.type,
    required this.resources,
    this.points = 0,
    this.isActive = true,
    this.faction,
    required this.metadata,
  });

  /// Factory für menschliche Spieler
  factory Player.human({
    required String id,
    required String name,
    ResourcesCollection? resources,
    int points = 0,
    String? faction,
    Map<String, dynamic>? metadata,
  }) {
    return Player(
      id: id,
      name: name,
      type: PlayerType.human,
      resources: resources ?? ResourcesCollection.initial(),
      points: points,
      faction: faction,
      metadata: metadata ?? {},
    );
  }

  /// Factory für KI-Spieler
  factory Player.ai({
    required String id,
    required String name,
    ResourcesCollection? resources,
    int points = 0,
    String? faction,
    Map<String, dynamic>? metadata,
  }) {
    return Player(
      id: id,
      name: name,
      type: PlayerType.ai,
      resources: resources ?? ResourcesCollection.initial(),
      points: points,
      faction: faction,
      metadata: metadata ?? {},
    );
  }

  /// Erstellt einen Standard-Spieler
  factory Player.defaultPlayer() {
    return Player.human(
      id: 'player',
      name: 'Player',
      resources: ResourcesCollection.initial(),
    );
  }

  bool get isHuman => type == PlayerType.human;
  bool get isAI => type == PlayerType.ai;

  Player copyWith({
    String? id,
    String? name,
    PlayerType? type,
    ResourcesCollection? resources,
    int? points,
    bool? isActive,
    String? faction,
    Map<String, dynamic>? metadata,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      resources: resources ?? this.resources,
      points: points ?? this.points,
      isActive: isActive ?? this.isActive,
      faction: faction ?? this.faction,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Aktualisiert die Ressourcen des Spielers
  Player updateResources(ResourcesCollection newResources) {
    return copyWith(resources: newResources);
  }

  /// Addiert Punkte zum aktuellen Score
  Player addPoints(int additionalPoints) {
    return copyWith(points: points + additionalPoints);
  }

  /// Deaktiviert den Spieler
  Player deactivate() {
    return copyWith(isActive: false);
  }

  /// Aktiviert den Spieler
  Player activate() {
    return copyWith(isActive: true);
  }

  /// Aktualisiert Metadaten
  Player updateMetadata(Map<String, dynamic> newMetadata) {
    final updatedMetadata = Map<String, dynamic>.from(metadata);
    updatedMetadata.addAll(newMetadata);
    return copyWith(metadata: updatedMetadata);
  }

  /// Serialisierung zu JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'resources': resources.toJson(),
      'points': points,
      'isActive': isActive,
      'faction': faction,
      'metadata': metadata,
    };
  }

  /// Deserialisierung von JSON
  factory Player.fromJson(Map<String, dynamic> json) {
    PlayerType playerType;
    switch (json['type']) {
      case 'human':
        playerType = PlayerType.human;
        break;
      case 'ai':
        playerType = PlayerType.ai;
        break;
      default:
        playerType = PlayerType.human;
    }

    return Player(
      id: json['id'],
      name: json['name'],
      type: playerType,
      resources: json['resources'] != null 
          ? ResourcesCollection.fromJson(json['resources'])
          : ResourcesCollection.initial(),
      points: json['points'] ?? 0,
      isActive: json['isActive'] ?? true,
      faction: json['faction'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    resources,
    points,
    isActive,
    faction,
    metadata,
  ];

  @override
  String toString() {
    return 'Player(id: $id, name: $name, type: $type, points: $points, isActive: $isActive)';
  }
}

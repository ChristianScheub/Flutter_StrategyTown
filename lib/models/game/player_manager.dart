import 'package:flutter_sim_city/models/game/player.dart';
import 'package:flutter_sim_city/models/resource/resources_collection.dart';

/// Manager-Klasse für die Verwaltung aller Spieler im Spiel
class PlayerManager {
  final Map<String, Player> _players;

  const PlayerManager({Map<String, Player>? players}) 
      : _players = players ?? const {};

  /// Factory für einen leeren PlayerManager
  factory PlayerManager.empty() {
    return const PlayerManager();
  }

  /// Factory mit Standard-Spieler
  factory PlayerManager.withDefaultPlayer() {
    final defaultPlayer = Player.defaultPlayer();
    return PlayerManager(players: {defaultPlayer.id: defaultPlayer});
  }

  /// Factory mit Standard-Spieler und KI
  factory PlayerManager.withDefaultPlayersAndAI() {
    final humanPlayer = Player.human(
      id: 'player',
      name: 'Player',
      resources: ResourcesCollection.initial(),
    );
    
    final aiPlayer = Player.ai(
      id: 'ai_player',
      name: 'AI Opponent',
      resources: ResourcesCollection.initial(),
    );
    
    return PlayerManager(players: {
      humanPlayer.id: humanPlayer,
      aiPlayer.id: aiPlayer,
    });
  }

  /// Alle Spieler als Map
  Map<String, Player> get players => Map.unmodifiable(_players);

  /// Alle Spieler als Liste
  List<Player> get allPlayers => _players.values.toList();

  /// Anzahl aller Spieler
  int get playerCount => _players.length;

  /// Aktive Spieler
  List<Player> get activePlayers => 
      _players.values.where((player) => player.isActive).toList();

  /// Anzahl aktiver Spieler
  int get activePlayerCount => activePlayers.length;

  /// Menschliche Spieler
  List<Player> get humanPlayers => 
      _players.values.where((player) => player.isHuman).toList();

  /// KI-Spieler
  List<Player> get aiPlayers => 
      _players.values.where((player) => player.isAI).toList();

  /// Anzahl menschlicher Spieler
  int get humanPlayerCount => humanPlayers.length;

  /// Anzahl KI-Spieler
  int get aiPlayerCount => aiPlayers.length;

  /// Ist Mehrspieler-Spiel - immer true, da wir nun stets im Mehrspielermodus sind
  bool get isMultiplayer => true;

  /// Spieler-IDs
  List<String> get playerIds => _players.keys.toList();

  /// Überprüft, ob ein Spieler existiert
  bool hasPlayer(String playerId) => _players.containsKey(playerId);

  /// Holt einen Spieler by ID
  Player? getPlayer(String playerId) => _players[playerId];

  /// Holt einen Spieler by ID oder wirft Exception
  Player getPlayerOrThrow(String playerId) {
    final player = _players[playerId];
    if (player == null) {
      throw ArgumentError('Player with ID "$playerId" not found');
    }
    return player;
  }

  /// Überprüft, ob ein Spieler KI ist
  bool isAIPlayer(String playerId) {
    final player = _players[playerId];
    return player?.isAI ?? false;
  }

  /// Überprüft, ob ein Spieler menschlich ist
  bool isHumanPlayer(String playerId) {
    final player = _players[playerId];
    return player?.isHuman ?? false;
  }

  /// Fügt einen Spieler hinzu
  PlayerManager addPlayer(Player player) {
    if (_players.containsKey(player.id)) {
      throw ArgumentError('Player with ID "${player.id}" already exists');
    }
    
    final newPlayers = Map<String, Player>.from(_players);
    newPlayers[player.id] = player;
    return PlayerManager(players: newPlayers);
  }

  /// Entfernt einen Spieler
  PlayerManager removePlayer(String playerId) {
    if (!_players.containsKey(playerId)) {
      return this; // Spieler existiert nicht
    }
    
    final newPlayers = Map<String, Player>.from(_players);
    newPlayers.remove(playerId);
    return PlayerManager(players: newPlayers);
  }

  /// Aktualisiert einen Spieler
  PlayerManager updatePlayer(Player updatedPlayer) {
    if (!_players.containsKey(updatedPlayer.id)) {
      throw ArgumentError('Player with ID "${updatedPlayer.id}" not found');
    }
    
    final newPlayers = Map<String, Player>.from(_players);
    newPlayers[updatedPlayer.id] = updatedPlayer;
    return PlayerManager(players: newPlayers);
  }

  /// Generiert eine eindeutige KI-ID
  String generateUniqueAIId() {
    int aiCounter = 1;
    String aiId = 'ai$aiCounter';
    
    while (hasPlayer(aiId)) {
      aiCounter++;
      aiId = 'ai$aiCounter';
    }
    
    return aiId;
  }

  /// Fügt einen menschlichen Spieler hinzu
  PlayerManager addHumanPlayer({
    required String name,
    String? id,
    ResourcesCollection? resources,
    int points = 0,
    String? faction,
    Map<String, dynamic>? metadata,
  }) {
    final playerId = id ?? name.toLowerCase().replaceAll(' ', '_');
    
    final player = Player.human(
      id: playerId,
      name: name,
      resources: resources,
      points: points,
      faction: faction,
      metadata: metadata,
    );
    
    return addPlayer(player);
  }

  /// Fügt einen KI-Spieler hinzu
  PlayerManager addAIPlayer({
    required String name,
    String? id,
    ResourcesCollection? resources,
    int points = 0,
    String? faction,
    Map<String, dynamic>? metadata,
  }) {
    final playerId = id ?? generateUniqueAIId();
    
    final player = Player.ai(
      id: playerId,
      name: name,
      resources: resources,
      points: points,
      faction: faction,
      metadata: metadata,
    );
    
    return addPlayer(player);
  }

  /// Fügt mehrere KI-Spieler hinzu
  PlayerManager addMultipleAIPlayers(int count, {String namePrefix = 'AI Player'}) {
    PlayerManager manager = this;
    
    for (int i = 0; i < count; i++) {
      final aiId = manager.generateUniqueAIId();
      final aiName = '$namePrefix ${aiId.substring(2)}'; // Remove 'ai' prefix for display
      manager = manager.addAIPlayer(name: aiName, id: aiId);
    }
    
    return manager;
  }

  /// Aktualisiert die Ressourcen eines Spielers
  PlayerManager updatePlayerResources(String playerId, ResourcesCollection resources) {
    final player = getPlayerOrThrow(playerId);
    return updatePlayer(player.updateResources(resources));
  }

  /// Fügt Punkte zu einem Spieler hinzu
  PlayerManager addPlayerPoints(String playerId, int points) {
    final player = getPlayerOrThrow(playerId);
    return updatePlayer(player.addPoints(points));
  }

  /// Deaktiviert einen Spieler
  PlayerManager deactivatePlayer(String playerId) {
    final player = getPlayerOrThrow(playerId);
    return updatePlayer(player.deactivate());
  }

  /// Aktiviert einen Spieler
  PlayerManager activatePlayer(String playerId) {
    final player = getPlayerOrThrow(playerId);
    return updatePlayer(player.activate());
  }

  /// Entfernt inaktive Spieler
  PlayerManager removeInactivePlayers() {
    final inactivePlayers = _players.values
        .where((player) => !player.isActive)
        .map((player) => player.id)
        .toList();
    
    PlayerManager manager = this;
    for (final playerId in inactivePlayers) {
      manager = manager.removePlayer(playerId);
    }
    
    return manager;
  }

  /// Holt Spieler-Statistiken
  Map<String, Map<String, dynamic>> getPlayerStatistics() {
    final stats = <String, Map<String, dynamic>>{};
    
    for (final player in _players.values) {
      stats[player.id] = {
        'name': player.name,
        'type': player.type.toString().split('.').last,
        'points': player.points,
        'isActive': player.isActive,
        'resources': player.resources.toJson(),
      };
    }
    
    return stats;
  }

  /// Kopiert den PlayerManager
  PlayerManager copyWith({Map<String, Player>? players}) {
    return PlayerManager(players: players ?? _players);
  }

  /// Serialisierung zu JSON
  Map<String, dynamic> toJson() {
    final playersJson = <String, dynamic>{};
    for (final entry in _players.entries) {
      playersJson[entry.key] = entry.value.toJson();
    }
    return {'players': playersJson};
  }

  /// Deserialisierung von JSON
  factory PlayerManager.fromJson(Map<String, dynamic> json) {
    final playersData = json['players'] as Map<String, dynamic>? ?? {};
    final players = <String, Player>{};
    
    for (final entry in playersData.entries) {
      players[entry.key] = Player.fromJson(entry.value);
    }
    
    return PlayerManager(players: players);
  }

  @override
  String toString() {
    return 'PlayerManager(players: ${_players.length}, active: $activePlayerCount, human: $humanPlayerCount, ai: $aiPlayerCount)';
  }
}

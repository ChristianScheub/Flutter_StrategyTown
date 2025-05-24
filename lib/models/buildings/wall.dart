import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:uuid/uuid.dart';

class Wall extends Building {
  static const int baseHealth = 200;
  
  final int currentHealth;
  final int maxHealth;

  Wall({
    required String id,
    required Position position,
    required int level,
    this.currentHealth = baseHealth,
    this.maxHealth = baseHealth,
    String ownerID = 'player',
  }) : super(
          id: id,
          type: BuildingType.wall,
          position: position,
          level: level,
          ownerID: ownerID,
        );

  factory Wall.create(Position position, {required String ownerID}) {
    return Wall(
      id: const Uuid().v4(),
      position: position,
      level: 1,
    );
  }

  @override
  Wall applyUpgradeValues() {
    // Erhöhe maxHealth und currentHealth pro Level
    return copyWith(
      maxHealth: (maxHealth * 1.2).round(),
      currentHealth: (currentHealth * 1.2).round(),
    );
  }

  @override
  Wall copyWith({
    String? id,
    BuildingType? type,
    Position? position,
    int? level,
    int? currentHealth,
    int? maxHealth,
    String? ownerID,
  }) {
    return Wall(
      id: id ?? this.id,
      position: position ?? this.position,
      level: level ?? this.level,
      currentHealth: currentHealth ?? this.currentHealth,
      maxHealth: maxHealth ?? this.maxHealth,
      ownerID: ownerID ?? this.ownerID,
    );
  }

  Wall repair() {
    return copyWith(currentHealth: maxHealth);
  }

  @override
  List<Object?> get props => [...super.props, currentHealth, maxHealth];
}

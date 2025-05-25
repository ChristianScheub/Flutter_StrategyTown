import 'building.dart';
import 'building_abilities.dart';
import '../map/position.dart';
import '../resource/resource.dart';
import 'package:uuid/uuid.dart';

class Warehouse extends Building implements ResourceStorage {
  final int baseStorage;
  final Map<ResourceType, int> _currentStorage = {};

  Warehouse({
    required String id,
    required Position position,
    int level = 1,
    required this.baseStorage,
    int? maxHealth,
    int? currentHealth,
    required String ownerID,
  }) : super(
          id: id,
          type: BuildingType.warehouse,
          position: position,
          level: level,
          maxHealth: maxHealth,
          currentHealth: currentHealth,
          ownerID: ownerID,
        );

  factory Warehouse.create(Position position, {int? baseStorage, required String ownerID}) {
    return Warehouse(
      id: const Uuid().v4(),
      position: position,
      baseStorage: baseStorage ?? 100,
      ownerID: ownerID,
    );
  }

  @override
  Warehouse copyWith({
    String? id,
    BuildingType? type,
    Position? position,
    int? level,
    int? maxHealth,
    int? currentHealth,
    String? ownerID,
    int? baseStorage,
  }) {
    return Warehouse(
      id: id ?? this.id,
      position: position ?? this.position,
      level: level ?? this.level,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      ownerID: ownerID ?? this.ownerID,
      baseStorage: baseStorage ?? this.baseStorage,
    );
  }

  @override
  Warehouse upgrade() {
    return copyWith(
      level: level + 1,
      maxHealth: (maxHealth * 1.2).round(),
      baseStorage: (baseStorage * 1.4).round(), // 40% mehr Speicherkapazität pro Level
    );
  }

  @override
  Warehouse applyUpgradeValues() {
    // Beispiel: erhöhe das Lager pro Level
    return copyWith(
      baseStorage: (baseStorage * 1.3).round(),
    );
  }

  // ResourceStorage implementation
  @override
  Map<ResourceType, int> get storageCapacity {
    final capacity = (baseStorage * (1 + (level - 1) * 0.4)).round(); // +40% pro Level
    return {
      ResourceType.wood: capacity,
      ResourceType.stone: capacity,
      ResourceType.food: capacity,
      ResourceType.iron: capacity,
    };
  }

  @override
  Map<ResourceType, int> get currentStorage => Map.unmodifiable(_currentStorage);

  @override
  bool canStore(ResourceType type, int amount) {
    final current = _currentStorage[type] ?? 0;
    final capacity = storageCapacity[type] ?? 0;
    return current + amount <= capacity;
  }

  @override
  bool addResources(ResourceType type, int amount) {
    if (!canStore(type, amount)) return false;
    _currentStorage[type] = (_currentStorage[type] ?? 0) + amount;
    return true;
  }

  @override
  bool removeResources(ResourceType type, int amount) {
    final current = _currentStorage[type] ?? 0;
    if (current < amount) return false;
    _currentStorage[type] = current - amount;
    return true;
  }

  @override
  List<Object?> get props => [...super.props, baseStorage, _currentStorage];
}
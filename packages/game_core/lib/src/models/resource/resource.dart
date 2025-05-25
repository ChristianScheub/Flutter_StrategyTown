import 'package:equatable/equatable.dart';

enum ResourceType {
  wood,
  stone,
  iron,
  food,
}

class Resource extends Equatable {
  final ResourceType type;
  final int amount;

  const Resource({
    required this.type,
    required this.amount,
  });

  Resource copyWith({
    ResourceType? type,
    int? amount,
  }) {
    return Resource(
      type: type ?? this.type,
      amount: amount ?? this.amount,
    );
  }

  Resource operator +(Resource other) {
    if (type != other.type) {
      throw ArgumentError('Cannot add resources of different types');
    }
    return Resource(
      type: type,
      amount: amount + other.amount,
    );
  }

  Resource operator -(Resource other) {
    if (type != other.type) {
      throw ArgumentError('Cannot subtract resources of different types');
    }
    return Resource(
      type: type,
      amount: amount - other.amount,
    );
  }

  @override
  List<Object?> get props => [type, amount];

  @override
  String toString() => '$type: $amount';

  String get name => type.toString().split('.').last;

  String get displayName => '${name[0].toUpperCase()}${name.substring(1)}';

  static final Map<ResourceType, String> resourceIcons = {
    ResourceType.wood: '🌲',
    ResourceType.stone: '🪨',
    ResourceType.iron: '⛏️',
    ResourceType.food: '🌾',
  };

  String get icon => resourceIcons[type] ?? '?';
}
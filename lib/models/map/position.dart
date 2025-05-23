import 'package:equatable/equatable.dart';

class Position extends Equatable {
  final int x;
  final int y;

  const Position({required this.x, required this.y});
  
  // Serialization methods
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }
  
  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      x: json['x'],
      y: json['y'],
    );
  }

  Position copyWith({int? x, int? y}) {
    return Position(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  Position operator +(Position other) {
    return Position(
      x: x + other.x,
      y: y + other.y,
    );
  }

  Position operator -(Position other) {
    return Position(
      x: x - other.x,
      y: y - other.y,
    );
  }

  bool isAdjacent(Position other) {
    final dx = (x - other.x).abs();
    final dy = (y - other.y).abs();
    return (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
  }

  // Berechnet die Manhattan-Distanz zwischen zwei Positionen (Bewegung nur orthogonal)
  int manhattanDistance(Position other) {
    return (x - other.x).abs() + (y - other.y).abs();
  }

  double distanceTo(Position other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return (dx * dx + dy * dy).toDouble();
  }

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => 'Position($x, $y)';
}
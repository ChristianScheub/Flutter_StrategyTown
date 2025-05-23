// Unit capability base class
import 'package:equatable/equatable.dart';

/// Basisklasse für alle Fähigkeiten einer Einheit
abstract class UnitCapability extends Equatable {
  const UnitCapability();
  
  UnitCapability copyWith();
  
  @override
  List<Object?> get props;
}

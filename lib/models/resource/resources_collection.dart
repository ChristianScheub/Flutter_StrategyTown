import 'package:equatable/equatable.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';

class ResourcesCollection extends Equatable {
  final Map<ResourceType, Resource> resources;

  const ResourcesCollection({
    required this.resources,
  });

  factory ResourcesCollection.empty() {
    return ResourcesCollection(
      resources: {
        for (final type in ResourceType.values) 
          type: Resource(type: type, amount: 0),
      },
    );
  }

  factory ResourcesCollection.initial() {
    return ResourcesCollection(
      resources: {
        ResourceType.wood: Resource(type: ResourceType.wood, amount: 500),
        ResourceType.stone: Resource(type: ResourceType.stone, amount: 200),
        ResourceType.iron: Resource(type: ResourceType.iron, amount: 100),
        ResourceType.food: Resource(type: ResourceType.food, amount: 200),
      },
    );
  }

  int getAmount(ResourceType type) {
    return resources[type]?.amount ?? 0;
  }

  ResourcesCollection copyWith({
    Map<ResourceType, Resource>? resources,
  }) {
    return ResourcesCollection(
      resources: resources ?? Map.from(this.resources),
    );
  }

  ResourcesCollection add(ResourceType type, int amount) {
    final newResources = Map<ResourceType, Resource>.from(resources);
    final currentResource = newResources[type] ?? Resource(type: type, amount: 0);
    final newResource = currentResource + Resource(type: type, amount: amount);
    newResources[type] = newResource;
    return ResourcesCollection(resources: newResources);
  }

  ResourcesCollection addMultiple(Map<ResourceType, int> toAdd) {
    final newResources = Map<ResourceType, Resource>.from(resources);
    for (final entry in toAdd.entries) {
      final currentResource = newResources[entry.key] ?? Resource(type: entry.key, amount: 0);
      final resourceToAdd = Resource(type: entry.key, amount: entry.value);
      newResources[entry.key] = currentResource + resourceToAdd;
    }
    return ResourcesCollection(resources: newResources);
  }

  ResourcesCollection subtract(ResourceType type, int amount) {
    final newResources = Map<ResourceType, Resource>.from(resources);
    final currentResource = newResources[type] ?? Resource(type: type, amount: 0);
    
    if (currentResource.amount < amount) {
      throw Exception('Not enough resources');
    }
    
    final newResource = currentResource - Resource(type: type, amount: amount);
    newResources[type] = newResource;
    return ResourcesCollection(resources: newResources);
  }

  bool hasEnough(ResourceType type, int amount) {
    final resource = resources[type];
    return resource != null && resource.amount >= amount;
  }

  bool hasEnoughMultiple(Map<ResourceType, int> required) {
    for (final entry in required.entries) {
      if (!hasEnough(entry.key, entry.value)) {
        return false;
      }
    }
    return true;
  }

  ResourcesCollection subtractMultiple(Map<ResourceType, int> toSubtract) {
    if (!hasEnoughMultiple(toSubtract)) {
      throw Exception('Not enough resources');
    }
    
    final newResources = Map<ResourceType, Resource>.from(resources);
    for (final entry in toSubtract.entries) {
      final currentResource = newResources[entry.key]!;
      final resourceToSubtract = Resource(type: entry.key, amount: entry.value);
      newResources[entry.key] = currentResource - resourceToSubtract;
    }
    return ResourcesCollection(resources: newResources);
  }

  // Serialization methods
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};
    resources.forEach((key, resource) {
      result[key.toString().split('.').last] = resource.amount;
    });
    return result;
  }
  
  factory ResourcesCollection.fromJson(Map<String, dynamic> json) {
    final Map<ResourceType, Resource> resourcesMap = {};
    
    json.forEach((key, value) {
      // Find the matching resource type
      final resourceType = ResourceType.values.firstWhere(
        (type) => type.toString().split('.').last == key,
        orElse: () => ResourceType.food, // Default fallback
      );
      resourcesMap[resourceType] = Resource(type: resourceType, amount: value);
    });
    
    return ResourcesCollection(resources: resourcesMap);
  }

  @override
  List<Object?> get props => [resources];
}
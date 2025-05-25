import 'package:flutter/material.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/models/resource/resources_collection.dart';

class ResourcePanel extends StatelessWidget {
  final ResourcesCollection resources;
  final String? playerName;
  final String? playerId;

  const ResourcePanel({
    super.key,
    required this.resources,
    this.playerName,
    this.playerId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Player info header (if available)
          if (playerName != null || playerId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                playerName != null ? '$playerName\'s Resources' : 'Player $playerId Resources',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Resources row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ResourceType.values.map((type) {
              return ResourceDisplay(
                type: type,
                amount: resources.getAmount(type),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class ResourceDisplay extends StatelessWidget {
  final ResourceType type;
  final int amount;

  const ResourceDisplay({
    super.key,
    required this.type,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getResourceColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getResourceColor(),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            Resource.resourceIcons[type] ?? '',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getResourceName(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                '$amount',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getResourceName() {
    switch (type) {
      case ResourceType.wood:
        return 'Wood';
      case ResourceType.stone:
        return 'Stone';
      case ResourceType.iron:
        return 'Iron';
      case ResourceType.food:
        return 'Food';
    }
  }

  Color _getResourceColor() {
    switch (type) {
      case ResourceType.wood:
        return const Color(0xFF795548);
      case ResourceType.stone:
        return const Color(0xFF607D8B);
      case ResourceType.iron:
        return const Color(0xFF9E9E9E);
      case ResourceType.food:
        return const Color(0xFF8BC34A);
    }
  }
}
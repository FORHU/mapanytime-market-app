import 'package:flutter/material.dart';

class WorldMapFloatingControls extends StatelessWidget {
  const WorldMapFloatingControls({
    required this.is3DMode,
    required this.isListView,
    required this.onToggle3DMode,
    required this.onToggleListView,
    required this.onStyleSelected,
    super.key,
  });

  final bool is3DMode;
  final bool isListView;
  final VoidCallback onToggle3DMode;
  final VoidCallback onToggleListView;
  final ValueChanged<String> onStyleSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isListView) ...[
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: Icon(
                is3DMode ? Icons.threed_rotation : Icons.map,
                color: Colors.black87,
              ),
              onPressed: onToggle3DMode,
            ),
          ),
          const SizedBox(height: 8),
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.layers, color: Colors.black87),
            ),
            onSelected: onStyleSelected,
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'mapbox://styles/mapbox/streets-v12',
                child: Text('Streets'),
              ),
              const PopupMenuItem<String>(
                value: 'mapbox://styles/mapbox/satellite-streets-v12',
                child: Text('Satellite Streets'),
              ),
              const PopupMenuItem<String>(
                value: 'mapbox://styles/mapbox/dark-v11',
                child: Text('Dark Mode'),
              ),
              const PopupMenuItem<String>(
                value: 'mapbox://styles/mapbox/light-v11',
                child: Text('Light Mode'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: Icon(
              isListView ? Icons.map : Icons.insert_drive_file_outlined,
              color: Colors.black87,
            ),
            onPressed: onToggleListView,
            tooltip: isListView ? 'Switch to Map' : 'Switch to List',
          ),
        ),
      ],
    );
  }
}

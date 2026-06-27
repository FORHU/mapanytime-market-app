import 'package:flutter/material.dart';

class WorldMapFloatingControls extends StatelessWidget {
  const WorldMapFloatingControls({
    required this.onStyleSelected,
    required this.onLocateMe,
    super.key,
  });

  final ValueChanged<String> onStyleSelected;
  final VoidCallback onLocateMe;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.my_location, color: Colors.black87),
              onPressed: onLocateMe,
              tooltip: 'Locate Me',
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
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WorldMapPage extends StatefulWidget {
  const WorldMapPage({super.key});

  @override
  State<WorldMapPage> createState() => _WorldMapPageState();
}

class _WorldMapPageState extends State<WorldMapPage> {
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(-6.2088, 106.8456),
    zoom: 14.4746,
  );

  late GoogleMapController mapController;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.worldMap)),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: _kGooglePlex,
      ),
    );
  }
}

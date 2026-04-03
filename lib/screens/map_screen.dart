import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Initial center based on campus location (roughly SHSU campus as in reference)
  final LatLng _campusCenter = const LatLng(30.71475020, -95.54687941);
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(_campusCenter, 18.0);
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _campusCenter,
          initialZoom: 18.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate, 
          ),
        ),
        children: [
          TileLayer(
            // Using standard OpenStreetMap tiles
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.uninav.campusnavigation',
            maxNativeZoom: 19,
          ),
          // Placeholder for future routes and POIs
          MarkerLayer(
            markers: [
              Marker(
                point: _campusCenter,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Future: open navigation dialog or bottom sheet here
        },
        child: const Icon(Icons.directions),
      ),
    );
  }
}

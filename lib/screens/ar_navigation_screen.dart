import 'package:flutter/material.dart';
import 'package:ar_location_view/ar_location_view.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

class ARNavigationScreen extends StatefulWidget {
  final List<ll.LatLng> routeCoordinates;

  const ARNavigationScreen({super.key, required this.routeCoordinates});

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen> {
  List<Annotation> annotations = [];
  bool hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    setState(() {
      hasPermissions = true;
      _buildAnnotations();
    });
  }

  void _buildAnnotations() {
    // Convert our route to AR annotations
    List<Annotation> routeAnnotations = [];
    for (int i = 0; i < widget.routeCoordinates.length; i++) {
        final point = widget.routeCoordinates[i];
        routeAnnotations.add(
            Annotation(
                uid: 'route_waypoint_\$i',
                position: Position(
                    longitude: point.longitude,
                    latitude: point.latitude,
                    timestamp: DateTime.now(),
                    accuracy: 0.0,
                    altitude: 0.0,
                    altitudeAccuracy: 0.0,
                    heading: 0.0,
                    headingAccuracy: 0.0,
                    speed: 0.0,
                    speedAccuracy: 0.0,
                ),
            ),
        );
    }
    
    // To not clutter the screen, we might only want to show the NEXT few points,
    // but for simple demo, we show all.
    annotations = routeAnnotations;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermissions) {
      return Scaffold(
        appBar: AppBar(title: const Text('AR Navigation')),
        body: const Center(child: Text('Location and Camera permissions required.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Mode'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: ArLocationWidget(
        annotations: annotations,
        showDistance: true,
        annotationBuilder: (context, annotation, distance) {
          // Floating pin design
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: Text(
                  '${distance.round()}m',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 4),
              const Icon(
                Icons.location_on,
                size: 60,
                color: Colors.redAccent,
              ),
            ],
          );
        },
        onLocationChange: (position) {
          // Optional: handle user moving.
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/navigation_engine.dart';
import '../models/navigation_models.dart';
import '../widgets/search_bottom_sheet.dart';
import '../widgets/directions_bottom_sheet.dart';
import '../widgets/app_drawer.dart';
import 'ar_navigation_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Initial center based on CHARUSAT University campus location
  final LatLng _campusCenter = const LatLng(22.599589, 72.8205);
  final MapController _mapController = MapController();
  final NavigationEngine _engine = NavigationEngine();

  String? _startLocationName;
  String? _endLocationName;
  int? _startId;
  int? _endId;
  
  
  // We'll just draw the route linearly for now regardless of floor
  List<LatLng> _currentRouteCoordinates = [];
  List<String> _currentRouteInstructions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    await _engine.initialize();
    setState(() {
      _isLoading = false;
      // Default start ID if it exists (for example, a common entrance)
      // For now, we will leave it null until selected, or find a default.
    });
  }

  void _calculateAndDrawRoute() {
    if (_startId != null && _endId != null) {
      final path = _engine.calculateRoute(_startId!, _endId!);
      if (path != null) {
        setState(() {
          _currentRouteCoordinates = path.map((node) => node.coords).toList();
          _currentRouteInstructions = _engine.generateTextInstructions(path);
        });
        
        // Fit bounds to show the route
        if (_currentRouteCoordinates.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(_currentRouteCoordinates);
          _mapController.fitCamera(CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50.0),
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No valid route found.")),
        );
      }
    }
  }

  void _resetNavigation() {
    setState(() {
      _startId = null;
      _endId = null;
      _startLocationName = null;
      _endLocationName = null;
      _currentRouteCoordinates.clear();
      _currentRouteInstructions.clear();
    });
    _mapController.move(_campusCenter, 18.0);
  }

  void _showSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchBottomSheet(
        endpoints: _engine.endpointLocations,
        initialStart: _startLocationName,
        initialEnd: _endLocationName,
        onRouteSelected: (start, end) {
          setState(() {
            if (start != null && start.isNotEmpty) {
              _startLocationName = start;
              _startId = _engine.endpointLocations[start];
            } else {
              _startLocationName = null;
              _startId = null;
            }
            if (end != null && end.isNotEmpty) {
              _endLocationName = end;
              _endId = _engine.endpointLocations[end];
            } else {
              _endLocationName = null;
              _endId = null;
            }
          });
          _calculateAndDrawRoute();
        },
      ),
    );
  }

  void _showDirectionsDialog() {
    if (_currentRouteInstructions.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: DirectionsBottomSheet(
            instructions: _currentRouteInstructions,
            startLocation: _startLocationName ?? "Unknown",
            endLocation: _endLocationName ?? "Unknown",
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Navigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Map',
            onPressed: _resetNavigation,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Center Map',
            onPressed: () {
              _mapController.move(_campusCenter, 18.0);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              FlutterMap(
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
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.uninav.campusnavigation',
                    maxNativeZoom: 19,
                  ),
                  PolylineLayer(
                    polylines: [
                      if (_currentRouteCoordinates.isNotEmpty)
                        Polyline(
                          points: _currentRouteCoordinates,
                          strokeWidth: 5.0,
                          color: Colors.blueAccent,
                        ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // End marker
                      if (_currentRouteCoordinates.isNotEmpty)
                        Marker(
                          point: _currentRouteCoordinates.last,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      // Start marker
                      if (_currentRouteCoordinates.isNotEmpty)
                        Marker(
                          point: _currentRouteCoordinates.first,
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              // Top Overlay for current route info
              if (_currentRouteCoordinates.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('From: ${_startLocationName ?? "Unknown"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('To: ${_endLocationName ?? "Unknown"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _showDirectionsDialog,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.list_alt, size: 16, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text('View Steps', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _resetNavigation,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentRouteCoordinates.isNotEmpty)
            FloatingActionButton.extended(
              heroTag: 'ar_mode',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ARNavigationScreen(
                      routeCoordinates: _currentRouteCoordinates,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.view_in_ar),
              label: const Text("AR Mode"),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'search',
            onPressed: _showSearchDialog,
            child: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Mappage extends StatefulWidget {
  const Mappage({super.key});

  @override
  State<Mappage> createState() => _MappageState();
}

class _MappageState extends State<Mappage> {
  late MapController _mapController;
  double _zoomLevel = 13.0;
  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _routePoints = []; // Route to destination (blue)
  List<LatLng> _policeRoutePoints = []; // Route to police station (red)
  List<Marker> _policeStationMarkers =
      []; // List to store police station markers
  TextEditingController _latitudeController = TextEditingController();
  TextEditingController _longitudeController = TextEditingController();
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  /// Get the user's current GPS location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("Please enable location services.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar("Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar("Location permissions are permanently denied.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      if (_mapReady) {
        _mapController.move(_currentLocation!, _zoomLevel);
      }
    });
  }

  /// Calculate the distance between two LatLng points in meters
  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Validate if coordinates are within acceptable ranges
  bool _validateCoordinates(double lat, double lng) {
    if (lat < -90 || lat > 90) {
      _showSnackBar("Latitude must be between -90 and 90 degrees.");
      return false;
    }
    if (lng < -180 || lng > 180) {
      _showSnackBar("Longitude must be between -180 and 180 degrees.");
      return false;
    }
    return true;
  }

  /// Fetch nearby police stations within 50 km using OpenStreetMap Nominatim API
  Future<void> _fetchNearbyPoliceStations() async {
    if (_currentLocation == null) {
      _showSnackBar("Current location is not available.");
      return;
    }

    // Define a bounding box for 50 km radius (1 degree ≈ 111 km, so 50 km ≈ 0.45 degrees)
    const double radiusInDegrees = 0.45; // 50 km radius
    final double minLat = _currentLocation!.latitude - radiusInDegrees;
    final double maxLat = _currentLocation!.latitude + radiusInDegrees;
    final double minLon = _currentLocation!.longitude - radiusInDegrees;
    final double maxLon = _currentLocation!.longitude + radiusInDegrees;

    final String url =
        'https://nominatim.openstreetmap.org/search?'
        'q=police+station'
        '&format=json'
        '&limit=20' // Increase limit to get more results
        '&bounded=1'
        '&viewbox=$minLon,$maxLat,$maxLon,$minLat';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'YourAppName/1.0 (your.email@example.com)', // Replace with your app's user agent
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isEmpty) {
          _showSnackBar("No police stations found within 50 km.");
          return;
        }

        List<Marker> policeMarkers = [];
        for (var place in data) {
          final lat = double.parse(place['lat']);
          final lng = double.parse(place['lon']);
          final name = place['display_name'];

          // Calculate distance to ensure it's within 50 km
          final distance = _calculateDistance(
            _currentLocation!,
            LatLng(lat, lng),
          );
          if (distance <= 50000) {
            // 50 km in meters
            policeMarkers.add(
              Marker(
                point: LatLng(lat, lng),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    _showSnackBar("Selected: $name");
                    _fetchRouteToPoliceStation(
                      LatLng(lat, lng),
                    ); // Fetch route to this police station
                  },
                  child: const Icon(
                    Icons.local_police,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
              ),
            );
          }
        }
        setState(() {
          _policeStationMarkers = policeMarkers;
          if (_mapReady && _policeStationMarkers.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(
              _policeStationMarkers.map((m) => m.point).toList()
                ..add(_currentLocation!),
            );
            _mapController.fitCamera(
              CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50)),
            );
          }
        });
      } else {
        _showSnackBar(
          "Failed to fetch police stations: ${response.statusCode}",
        );
      }
    } catch (e) {
      _showSnackBar("Error fetching police stations: $e");
    }
  }

  /// Fetch route to a selected police station using OpenRouteService API
  Future<void> _fetchRouteToPoliceStation(LatLng policeStation) async {
    if (_currentLocation == null) {
      _showSnackBar("Current location is not available.");
      return;
    }

    const String apiKey =
        '5b3ce3597851110001cf6248c49b5fe3a80b48b589664aa5aa1ab15c';
    final String url =
        'https://api.openrouteservice.org/v2/directions/driving-car/geojson';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Authorization': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'coordinates': [
            [_currentLocation!.longitude, _currentLocation!.latitude],
            [policeStation.longitude, policeStation.latitude],
          ],
          'format': 'geojson',
          'radiuses': [1000, 1000],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['features'] == null || data['features'].isEmpty) {
          _showSnackBar("No route found to the police station.");
          return;
        }

        final geometry = data['features'][0]['geometry'];
        if (geometry == null || geometry['coordinates'] == null) {
          _showSnackBar("Invalid route data from server.");
          return;
        }

        final List<dynamic> coordinates = geometry['coordinates'];
        setState(() {
          _policeRoutePoints =
              coordinates
                  .map(
                    (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()),
                  )
                  .toList();

          if (_mapReady && _policeRoutePoints.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(_policeRoutePoints);
            _mapController.fitCamera(
              CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50)),
            );
          }
        });
      } else {
        _showSnackBar(
          "Failed to fetch route to police station: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      _showSnackBar("Error fetching route to police station: $e");
    }
  }

  /// Fetch the route to the destination using OpenRouteService API
  Future<void> _fetchRoute() async {
    if (_currentLocation == null || _destination == null) {
      _showSnackBar("Current location or destination is missing.");
      return;
    }

    double distanceInMeters = _calculateDistance(
      _currentLocation!,
      _destination!,
    );
    const double maxDistanceInMeters = 6000000.0;

    if (distanceInMeters > maxDistanceInMeters) {
      _showSnackBar(
        "The route distance (${(distanceInMeters / 1000).toStringAsFixed(2)} km) exceeds the maximum allowed distance of 6,000 km.",
      );
      return;
    }

    const String apiKey =
        '5b3ce3597851110001cf6248c49b5fe3a80b48b589664aa5aa1ab15c';
    final String url =
        'https://api.openrouteservice.org/v2/directions/driving-car/geojson';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Authorization': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'coordinates': [
            [_currentLocation!.longitude, _currentLocation!.latitude],
            [_destination!.longitude, _destination!.latitude],
          ],
          'format': 'geojson',
          'radiuses': [1000, 1000],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['features'] == null || data['features'].isEmpty) {
          _showSnackBar("No routes found.");
          return;
        }

        final geometry = data['features'][0]['geometry'];
        if (geometry == null || geometry['coordinates'] == null) {
          _showSnackBar("Invalid route data from server.");
          return;
        }

        final List<dynamic> coordinates = geometry['coordinates'];
        setState(() {
          _routePoints =
              coordinates
                  .map(
                    (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()),
                  )
                  .toList();

          if (_mapReady && _routePoints.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(_routePoints);
            _mapController.fitCamera(
              CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50)),
            );
          }
        });
      } else {
        _showSnackBar(
          "Failed to fetch route: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      _showSnackBar("Error fetching route: $e");
    }
  }

  /// Function to set the destination and fetch the route
  void _setDestination() {
    if (_latitudeController.text.isEmpty || _longitudeController.text.isEmpty) {
      _showSnackBar("Please enter both latitude and longitude.");
      return;
    }

    try {
      double lat = double.parse(_latitudeController.text.trim());
      double lng = double.parse(_longitudeController.text.trim());

      if (!_validateCoordinates(lat, lng)) {
        return;
      }

      setState(() {
        _destination = LatLng(lat, lng);
        _routePoints.clear();
        _policeRoutePoints
            .clear(); // Clear police route when setting a new destination
      });
      _fetchRoute();
    } catch (e) {
      _showSnackBar("Invalid coordinates: $e");
    }
  }

  /// Helper method to show SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map Page')),
      body: Stack(
        children: [
          if (_currentLocation == null)
            const Center(child: CircularProgressIndicator())
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation!,
                initialZoom: _zoomLevel,
                onMapReady: () {
                  setState(() {
                    _mapReady = true;
                    _mapController.move(_currentLocation!, _zoomLevel);
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  //subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.green,
                          size: 40,
                        ),
                      ),
                    if (_destination != null)
                      Marker(
                        point: _destination!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ..._policeStationMarkers, // Add police station markers
                  ],
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4.0,
                        color: Colors.blue, // Route to destination in blue
                      ),
                    ],
                  ),
                if (_policeRoutePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _policeRoutePoints,
                        strokeWidth: 4.0,
                        color: Colors.red, // Route to police station in red
                      ),
                    ],
                  ),
              ],
            ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _inputField(_latitudeController, "Latitude"),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _inputField(_longitudeController, "Longitude"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _setDestination,
                      child: const Text("Get Route"),
                    ),
                    ElevatedButton(
                      onPressed: _fetchNearbyPoliceStations,
                      child: const Text("Show Police Stations"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {
        setState(() {
          _mapController.move(_currentLocation!, _zoomLevel);
        });
      },
      child: Icon(
        Icons.my_location
      ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 0.1),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 0.1),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
    );
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
}

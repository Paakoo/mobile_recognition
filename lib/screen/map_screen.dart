// map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Location _location = Location();
  LatLng _manualLocation = LatLng(-7.770137159682122, 111.482021377044); // Jakarta as example
  LatLng? _userLocation;
  double _radius = 50.0; // Radius in meters
  bool _isUserWithinRadius = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // Check if location service is enabled
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // Check location permission
    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Get current location
    final locationData = await _location.getLocation();
    setState(() {
      _userLocation = LatLng(locationData.latitude!, locationData.longitude!);
      _checkIfUserWithinRadius();
    });
  }

  void _checkIfUserWithinRadius() {
    if (_userLocation != null) {
      final distance = Distance().as(LengthUnit.Meter, _manualLocation, _userLocation!);
      setState(() {
        _isUserWithinRadius = distance <= _radius;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaflet Map with Radius Check'),
      ),
      body: _userLocation == null
          ? Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: _manualLocation,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    // Manual location marker
                    Marker(
                      point: _manualLocation,
                      child: Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    // User location marker
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        child: Icon(
                          Icons.person_pin_circle,
                          color: Colors.green,
                          size: 40,
                        ),
                      ),
                  ],
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _manualLocation,
                      color: Colors.blue.withOpacity(0.3),
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.blue,
                      useRadiusInMeter: true, // Ensures radius remains consistent
                      radius: _radius,
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _fetchLocation(),
        child: Icon(Icons.my_location),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.all(16),
        child: Text(
          _isUserWithinRadius
              ? 'You are within the radius of the manual location.'
              : 'You are outside the radius of the manual location.',
          style: TextStyle(
            color: _isUserWithinRadius ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

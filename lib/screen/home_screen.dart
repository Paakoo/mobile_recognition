import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'nav_bar.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Replace single manual location with list
  final List<Map<String, dynamic>> _manualLocations = [
    {
      'name': 'Office Pertama',
      'location': LatLng(-7.770163593429085, 111.48197507858067),
    },
    {
      'name': 'PENS',
      
      'location': LatLng(-7.276631610635575, 112.79309730132333),
    },
    {
      'name': 'Office Kedua',
      'location': LatLng(-7.289138908277864, 112.79867124433288),
    },
  ];
  
  int _selectedOfficeIndex = 0;
  String? selectedLocation;
  bool isLocationSelected = false;
  final Location _location = Location();
  LatLng? _userLocation;
  double _radius = 50.0;
  bool _isUserWithinRadius = false;
  bool _isLocationServiceEnabled = false;
  String _currentTime = '';
  String _userName = '';
  Timer? _timer;
  bool _hasAttendanceToday = false; // Add this line

  @override
  void initState() {
    super.initState();
    _checkLocationService();
    _loadUserName();
    _updateTime();
    _checkPresenceStatus(); // Add this line
    _timer = Timer.periodic(Duration(seconds: 1), (timer) => _updateTime());
    initializeDateFormatting('id_ID');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationService() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        _showLocationDialog();
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        _showLocationDialog();
        return;
      }
    }

    setState(() => _isLocationServiceEnabled = true);
    _fetchLocation();
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Required'),
          content: Text('Please enable GPS and grant location permission to use this app.'),
          actions: [
            TextButton(
              child: Text('Settings'),
              onPressed: () async {
                Navigator.pop(context);
                await _location.requestService();
                await _checkLocationService();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchLocation() async {
    final locationData = await _location.getLocation();
    if(mounted){
      setState(() {
      _userLocation = LatLng(locationData.latitude!, locationData.longitude!);
      _checkIfUserWithinRadius();
    });
    }
  }

  void _checkIfUserWithinRadius() {
    if (_userLocation != null) {
      final selectedOffice = _manualLocations[_selectedOfficeIndex]['location'];
      final distance = Distance().as(
        LengthUnit.Meter,
        selectedOffice,
        _userLocation!
      );
      setState(() {
        _isUserWithinRadius = distance <= _radius;
      });
    }
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  Future<void> _loadUserName() async {
  final storage = FlutterSecureStorage();
  try {
    final token = await storage.read(key: 'jwt_token');
    if (token != null) {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      print('Decoded token: $decodedToken'); // Debug print
      
      final String name = decodedToken['sub'].toString();
      setState(() {
        _userName = name;
      });
    }
  } catch (e) {
    print('Error loading user name: $e');
    setState(() {
      _userName = 'User';
    });
  }
}

  Future<void> _restartGPS() async {
    setState(() => _isLocationServiceEnabled = false);
    await _location.requestService();
    await _checkLocationService();
  }

  Future<void> _checkPresenceStatus() async {
    final storage = FlutterSecureStorage();
    try {
      final token = await storage.read(key: 'jwt_token');
      if (token != null) {
        final response = await http.get(
          Uri.parse('http://172.20.10.2:5000/api/presencecheck?nama=$_userName'),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            _hasAttendanceToday = true;
          });
        } else if (response.statusCode == 400) {
          setState(() {
            _hasAttendanceToday = false;
          });
        }
      }
    } catch (e) {
      print('Error checking presence status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // title: Text('Attendance System', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[500],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[500]!, Colors.blue[50]!],
            stops: [0.0, 0.3],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // User Info Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome,',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            _userName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('EEEE, dd MMM yyyy','id_ID').format(DateTime.now()),
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            _currentTime,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Location Status Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Work Mode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLocationOption('WFO', Icons.business, selectedLocation == 'WFO'),
                          ),
                          Expanded(
                            child: _buildLocationOption('WFA', Icons.home, selectedLocation == 'WFA'),
                          ),
                        ],
                      ),
                      if (selectedLocation == 'WFO') ...[
                        SizedBox(height: 16),
                        Text(
                          'Select Office Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildOfficeSelector(),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Map Container
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _userLocation == null
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                          ),
                        )
                      : _buildMap(),
                ),
              ),
              
              // Status Message
              Container(
                margin: EdgeInsets.symmetric(vertical: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _getStatusColor()),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getStatusIcon(), color: _getStatusColor()),
                    SizedBox(width: 8),
                    Text(
                      _getStatusMessage(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Face Recognition Button
              ElevatedButton.icon(
                onPressed: _canStartRecognition() 
                  ? () async {
                      await _sendLocationData(
                        selectedLocation!,
                        _userLocation?.latitude,
                        _userLocation?.longitude
                      );
                    }: null,
                // icon: _hasAttendanceToday ? Icon(Icons.person) : Icon(Icons.person, color: Colors.white),
                label: Text(_hasAttendanceToday ? 'Sudah Melakukan Absensi' : 'Mulai Absensi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasAttendanceToday ? Colors.grey : Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavBar(
        currentIndex: 0, // 0 for home page
      ),
    );
  }

  Widget _buildLocationOption(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLocation = title;
          isLocationSelected = true;
        });
      },
      child: Container(
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (!_isLocationServiceEnabled) return Colors.red;
    if (!isLocationSelected) return Colors.orange;
    if (selectedLocation == 'WFA') return Colors.green;
    return _isUserWithinRadius ? Colors.green : Colors.red;
  }

  IconData _getStatusIcon() {
    if (!_isLocationServiceEnabled) return Icons.location_off;
    if (!isLocationSelected) return Icons.warning;
    if (selectedLocation == 'WFA') return Icons.check_circle;
    return _isUserWithinRadius ? Icons.check_circle : Icons.cancel;
  }

  String _getStatusMessage() {
    if (!_isLocationServiceEnabled) return 'Tolong hidupkan location services';
    if (!isLocationSelected) return 'Pilih work mode';
    if (selectedLocation == 'WFA') return 'WFA Mode';
    return _isUserWithinRadius
        ? 'Kamu berada di dalam radius'
        : 'Kamu berada di luar radius';
  }

  bool _canStartRecognition() {
    if (_hasAttendanceToday) return false;
    if (!_isLocationServiceEnabled) return false;
    if (!isLocationSelected) return false;
    if (_userLocation == null) return false;

    if (selectedLocation == 'WFO') {
      return _isUserWithinRadius;
    }
    
    return true;
  }

  Future<void> _sendLocationData(String locationType, double? latitude, double? longitude) async {
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'jwt_token');
  
  if (_userLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Location not available'))
    );
    return;
  }

  final String officeName = locationType == 'WFO' 
      ? _manualLocations[_selectedOfficeIndex]['name']
      : 'Work From Anywhere';

  final locationData = {
    'location_data': {
      'location_type': locationType,
      'office_name': officeName,
      'timestamp': DateTime.now().toIso8601String(),
      'latitude': _userLocation!.latitude.toString(),
      'longitude': _userLocation!.longitude.toString()
    }
  };

  try {
    final response = await http.post(
      Uri.parse('http://172.20.10.2:5000/api/getlocation'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(locationData),
    );

    if (response.statusCode == 200) {
      Navigator.pushNamed(context, '/liveness');
    } else {
      throw Exception('Failed to send location data');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'))
    );
  }
}

  Widget _buildMap() {
    if (selectedLocation == 'WFA') {
    return FlutterMap(
      options: MapOptions(
        initialCenter: _userLocation ?? _manualLocations[_selectedOfficeIndex]['location'],
        initialZoom: 16.0,
        minZoom: 16.0,
        maxZoom: 16.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        Stack(
          children: [
            MarkerLayer(
              markers: [
                if (_userLocation != null)
                  Marker(
                    point: _userLocation!,
                    child: Icon(Icons.person_pin_circle, color: Colors.blue),
                  ),
              ],
            ),
            Align(
              alignment: Alignment.topRight, // Menempatkan ikon di pojok kanan atas
              child: Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, // Warna latar belakang
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16), // Bentuk lingkaran
                ),
                child: IconButton(
                  icon: Icon(Icons.refresh, color: Colors.blue[700]),
                  onPressed: _restartGPS,
                  tooltip: 'Restart GPS',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

    return FlutterMap(
      options: MapOptions(
        initialCenter: _userLocation ??  _manualLocations[_selectedOfficeIndex]['location'],
        initialZoom: 18.0,
        minZoom: 18.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        Stack(
          children: [
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _manualLocations[_selectedOfficeIndex]['location'],
                  radius: _radius,
                  color: Colors.blue.withOpacity(0.3),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _manualLocations[_selectedOfficeIndex]['location'],
                  child: Icon(Icons.location_on, color: Colors.red),
                ),
                if (_userLocation != null)
                  Marker(
                    point: _userLocation!,
                    child: Icon(Icons.person_pin_circle, color: Colors.blue),
                  ),
              ],
            ),
            Align(
              alignment: Alignment.topRight, // Menempatkan ikon di pojok kanan atas
              child: Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, // Warna latar belakang
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16), // Bentuk lingkaran
                ),
                child: IconButton(
                  icon: Icon(Icons.refresh, color: Colors.blue[700]),
                  onPressed: _restartGPS,
                  tooltip: 'Restart GPS',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _logout(BuildContext context) async {
    final storage = FlutterSecureStorage();
    await storage.delete(key: 'jwt_token');
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildOfficeSelector() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: _selectedOfficeIndex,
          items: List.generate(_manualLocations.length, (index) {
            return DropdownMenuItem(
              value: index,
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue[700]),
                  SizedBox(width: 12),
                  Text(
                    _manualLocations[index]['name'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }),
          onChanged: (index) {
            if (index != null) {
              setState(() {
                _selectedOfficeIndex = index;
                _checkIfUserWithinRadius();
              });
            }
          },
        ),
      ),
    );
  }
}
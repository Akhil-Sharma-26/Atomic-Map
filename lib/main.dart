import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Completer<GoogleMapController> _controller = Completer();
  static const LatLng _center = const LatLng(45.521563, -122.677433);
  final Set<Marker> _markers = {};
  LatLng _lastMapPosition = _center;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final prefs = await SharedPreferences.getInstance();
    final markersData = prefs.getStringList('markers') ?? [];
    setState(() {
      _markers.clear();
      for (String markerData in markersData) {
        final data = markerData.split(',');
        final marker = Marker(
          markerId: MarkerId(data[0]),
          position: LatLng(double.parse(data[1]), double.parse(data[2])),
          infoWindow: InfoWindow(title: data[3]),
          icon: BitmapDescriptor.defaultMarker,
        );
        _markers.add(marker);
      }
    });
  }

  Future<void> _addMarkerWithDetails(LatLng position) async {
    final TextEditingController controller = TextEditingController();
    final prefs = await SharedPreferences.getInstance();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Details'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Details"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                final String details = controller.text;
                setState(() {
                  _markers.add(Marker(
                    markerId: MarkerId(position.toString()),
                    position: position,
                    infoWindow: InfoWindow(title: details),
                    icon: BitmapDescriptor.defaultMarker,
                  ));
                });
                // Save to local storage
                final String markerData = '${position.toString()},${position.latitude},${position.longitude},$details';
                final List<String> markersData = prefs.getStringList('markers') ?? [];
                markersData.add(markerData);
                await prefs.setStringList('markers', markersData);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _onAddMarkerButtonPressed() async {
    _addMarkerWithDetails(_lastMapPosition);
  }

  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geocoding'),
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
            onCameraMove: _onCameraMove,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FloatingActionButton(
                onPressed: _onAddMarkerButtonPressed,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                child: const Icon(Icons.add_location, size: 36.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
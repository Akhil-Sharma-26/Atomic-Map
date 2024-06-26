import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  static const LatLng _center = LatLng(31.9779626, 76.7832618);
  final Set<Marker> _markers = {}; // The marker array
  LatLng _lastMapPosition = _center;

  Future<void> _requestPermissions() async { // requestion Location
    await Permission.location.request();
  }


  @override
  void initState() { // things to start at initialization
    super.initState();
    _loadMarkers();
    _requestPermissions(); 
  }

Future<void> _addMarkerWithDetails(LatLng position) async {
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();
  final prefs = await SharedPreferences.getInstance();
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Enter Details for this location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller2,
              decoration: const InputDecoration(hintText: "Details"),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              final String title = controller.text;
              final String details = controller2.text;
              setState(() {
                _markers.add(Marker(
                  markerId: MarkerId(position.toString()),
                  position: position,
                  infoWindow: InfoWindow(title: title, snippet: details),
                  icon: BitmapDescriptor.defaultMarker,
                ));
              });
              // Save to local storage
              final String markerData = '${position.latitude},${position.longitude},$title,$details';
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

Future<void> _loadMarkers() async {
  final prefs = await SharedPreferences.getInstance();
  final markersData = prefs.getStringList('markers') ?? [];
  setState(() {
    _markers.clear(); // Clear existing markers before adding new ones

    for (String it in markersData) {
      final data = it.split(',');
      if (data.length >= 4) {
        try {
          final double lat = double.tryParse(data[0]) ?? 0.0;
          final double lng = double.tryParse(data[1]) ?? 0.0;
          final String title = data[2];
          final String details = data[3];

          // Only add the marker if both latitude and longitude are valid doubles
          if (lat != 0.0 && lng != 0.0) {
            final marker = Marker(
              markerId: MarkerId('$lat,$lng'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: title, snippet: details),
              icon: BitmapDescriptor.defaultMarker,
            );
            _markers.add(marker);
          } else {
            if (kDebugMode) {
              print("Invalid marker data: $it");
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print("Error parsing marker data: $e");
          }
        }
      }
    }
  });
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
        title: const Text('Atomic Maps'),
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _center,
              zoom: 15.0,
            ),
            markers: _markers,
            onCameraMove: _onCameraMove,
            compassEnabled: true,
            mapType: MapType.hybrid,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onTap: (argument) => _addMarkerWithDetails(argument),
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


// The Secret-gradle was not working, it was just because I put the local.properties files at wrong place.
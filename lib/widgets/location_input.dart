import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

import '../models/place_location.dart';
import '../screens/map_screen.dart';
import '../utils/constants.dart';

class LocationInput extends StatefulWidget {
  const LocationInput({
    super.key,
    required this.onSelectLocation,
    this.initialLocation,
  });

  final void Function(PlaceLocation location) onSelectLocation;
  final PlaceLocation? initialLocation;

  @override
  State<LocationInput> createState() {
    return _LocationInputState();
  }
}

class _LocationInputState extends State<LocationInput> {
  PlaceLocation? _pickedLocation;
  var _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
  }

  String get locationImage {
    if (_pickedLocation == null) {
      return '';
    }
    final lat = _pickedLocation!.latitude;
    final lng = _pickedLocation!.longitude;
    return 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng=&zoom=16&size=600x300&maptype=roadmap&markers=color:red%7Clabel:A%7C$lat,$lng&key=${AppConstants.googleMapsApiKey}';
  }

  Future<void> _savePlace(double latitude, double longitude) async {
    setState(() {
      _isGettingLocation = true;
    });

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=${AppConstants.googleMapsApiKey}');
    
    try {
      final response = await http.get(url);
      final resData = json.decode(response.body);
      
      String address = 'Unknown location';
      if (resData['results'] != null && (resData['results'] as List).isNotEmpty) {
        address = resData['results'][0]['formatted_address'];
      }

      setState(() {
        _pickedLocation = PlaceLocation(
          latitude: latitude,
          longitude: longitude,
          address: address,
        );
        _isGettingLocation = false;
      });
      widget.onSelectLocation(_pickedLocation!);
    } catch (e) {
      // Fallback if geocoding fails
      setState(() {
        _pickedLocation = PlaceLocation(
          latitude: latitude,
          longitude: longitude,
          address: 'Location ($latitude, $longitude)',
        );
        _isGettingLocation = false;
      });
      widget.onSelectLocation(_pickedLocation!);
    }
  }

  void _getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    setState(() {
      _isGettingLocation = true;
    });

    try {
      locationData = await location.getLocation();
      final lat = locationData.latitude;
      final lng = locationData.longitude;

      if (lat == null || lng == null) {
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      _savePlace(lat, lng);
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  void _selectOnMap() async {
    final pickedLocation = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (ctx) => MapScreen(
          isSelecting: true,
          location: _pickedLocation ?? const PlaceLocation(
            latitude: 37.422, // Default to a standard location if none picked
            longitude: -122.084,
            address: '',
          ),
        ),
      ),
    );
    if (pickedLocation == null) {
      return;
    }
    _savePlace(pickedLocation.latitude, pickedLocation.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget previewContent = Text(
      'No location chosen',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: isDark ? Colors.white54 : Colors.black54,
          ),
    );

    if (_pickedLocation != null) {
      previewContent = Image.network(
        locationImage,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (_isGettingLocation) {
      previewContent = const CircularProgressIndicator();
    }

    return Column(
      children: [
        Container(
          height: 170,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 1,
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: previewContent,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.location_on, size: 18),
                label: const Text('Current', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectOnMap,
                icon: const Icon(Icons.map, size: 18),
                label: const Text('From Map', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}

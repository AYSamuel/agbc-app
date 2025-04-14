import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:agbc_app/utils/theme.dart';

class LocationService {
  Future<String?> getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return 'Location permissions are permanently denied';
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return [
          if (place.locality != null) place.locality,
          if (place.country != null) place.country,
        ].where((element) => element != null).join(', ');
      }
      return null;
    } catch (e) {
      return 'Error getting location: $e';
    }
  }

  Future<bool> validateLocation(String location) async {
    if (location.isEmpty) return false;
    
    try {
      List<Location> locations = await locationFromAddress(location);
      return locations.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
} 
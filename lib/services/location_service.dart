import 'package:geolocator/geolocator.dart';

// Handles GPS permission checks, live location updates, and distance calculation.
class LocationService {
  // Check whether location services and permissions are available, and request them if needed.
  static Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Return a live stream of GPS positions while the user is walking.
  static Stream<Position> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  // Calculate the distance between two GPS points in meters.
  static double distanceBetween(
      Position start,
      Position end,
      ) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }
}
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;

class CustomLatLng {
  final double latitude;
  final double longitude;

  CustomLatLng(this.latitude, this.longitude);

  latlong2.LatLng toLatLng2() => latlong2.LatLng(latitude, longitude);
  google_maps.LatLng toGoogleMapsLatLng() => google_maps.LatLng(latitude, longitude);
  @override
  String toString() {
    return "($latitude,$longitude)";
  }
}
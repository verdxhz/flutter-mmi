import 'package:flutter/material.dart';
import 'customlatlong.dart';
import 'mapInterface.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';
class Googlemap extends StatefulWidget implements MapInterface {
  @override
  _GooglemapState createState() => _GooglemapState();

  @override
  Widget buildmap(CustomLatLng l, double z) {
    return GooglemapStateful(
      initialCenter: l,
      initialZoom: z,
    );
  }

  @override
  void deleteAllMarker() {
    _GooglemapState.instance?.deleteAllMarker();
  }

  @override
  void movemap(CustomLatLng l) {
    _GooglemapState.instance?.movemap(l);
  }

  @override
  void undo1Marker() {
    _GooglemapState.instance?.undo1Marker();
  }

  @override
  void addMarker(CustomLatLng l) {
    _GooglemapState.instance?.addMarker(l);
  }

  @override
  CustomLatLng getCenter() {
    return _GooglemapState.instance?.getCenter() ?? CustomLatLng(0, 0);
  }

  @override
  void setcontroller() {
    _GooglemapState.instance?.setcontroller();
  }

  @override
  double getZoom() {
    return _GooglemapState.instance?.getZoom() ?? 0.0;
  }
}

class GooglemapStateful extends StatefulWidget {
  final CustomLatLng initialCenter;
  final double initialZoom;

  GooglemapStateful({required this.initialCenter, required this.initialZoom});

  @override
  _GooglemapState createState() => _GooglemapState();
}

class _GooglemapState extends State<GooglemapStateful> {
  static _GooglemapState? instance;
  final Set<Marker> _markers = {};
  final List<LatLng> _points = [];
  final Set<Polyline> _polylines = {};
  late GoogleMapController mapController;
  late CustomLatLng mapCenter;
  late double zoom;
 

  _GooglemapState() {
    instance = this;
  }

  @override
  void initState() {
    super.initState();
    mapCenter = widget.initialCenter;
    zoom = widget.initialZoom;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (controller) {
        mapController = controller;
      },
      zoomControlsEnabled: false,
      initialCameraPosition: CameraPosition(
        target: mapCenter.toGoogleMapsLatLng(),
        zoom: zoom,
      ),
      onTap: (point) {
        
        addMarker(CustomLatLng(point.latitude, point.longitude));
        debugPrint("hai toccato $point");
      },
      markers: _markers,
      polylines: _polylines,
      onCameraMove: (position) {
        setState(() {
         
          mapCenter = CustomLatLng(position.target.latitude, position.target.longitude);
          zoom = position.zoom;
        });
        debugPrint('$mapCenter');
      },
    
    );
  }

  void addMarker(CustomLatLng l) {
    setState(() {
      final LatLng point = l.toGoogleMapsLatLng();
      _markers.add(
        Marker(
          markerId: MarkerId(l.toString()),
          position: point,
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
      _points.add(point);
      _updatePolylines();
    });
  }

  void _updatePolylines() {
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('polyline'),
          points: _points,
          color: const Color.fromARGB(255, 0, 0, 0),
          width: 3,
        ),
      );
    });
  }
  
  void deleteAllMarker() {
    setState(() {
      _markers.clear();
      _points.clear();
      _polylines.clear();
    });
  }

  void undo1Marker() {
    setState(() {
      if (_points.isNotEmpty) {
        _markers.removeWhere((marker) => marker.position == _points.last);
        _points.removeLast();
        _updatePolylines();
      }
    });
  }

  void movemap(CustomLatLng l) {
    mapController.animateCamera(CameraUpdate.newLatLngZoom(l.toGoogleMapsLatLng(), zoom));
  }

  CustomLatLng getCenter() {
    return mapCenter;
  }

  void setcontroller() {
    // Not needed for Google Map as the controller is set in onMapCreated
  }

  double getZoom() {
    return zoom;
  }
}




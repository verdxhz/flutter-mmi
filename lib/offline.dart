import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mbtiles/mbtiles.dart';
import 'customlatlong.dart';
import 'package:vector_map_tiles_mbtiles/vector_map_tiles_mbtiles.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

import 'mapInterface.dart';

class FluttermapOff extends StatefulWidget implements MapInterface {
  @override
  _FluttermapState createState() => _FluttermapState();

  @override
  Widget buildmap(CustomLatLng l, double z) {
    return FluttermapStateful(
      initialCenter: CustomLatLng(42,13),
      initialZoom: z,
    );
  }

  @override
  void deleteAllMarker() {
    _FluttermapState.instance?.deleteAllMarker();
  }

  @override
  void movemap(CustomLatLng l) {
    _FluttermapState.instance?.movemap(l);
  }

  @override
  void undo1Marker() {
    _FluttermapState.instance?.undo1Marker();
  }

  @override
  void addMarker(CustomLatLng l) {
    _FluttermapState.instance?.addMarker(l);
  }

  @override
  CustomLatLng getCenter() {
    return _FluttermapState.instance?.getCenter() ?? CustomLatLng(0, 0);
  }

  @override
  void setcontroller() {
    _FluttermapState.instance?.setcontroller();
  }

  @override
  double getZoom() {
    return _FluttermapState.instance?.getZoom() ?? 0.0;
  }
}

class FluttermapStateful extends StatefulWidget {
  final CustomLatLng initialCenter;
  final double initialZoom;

  FluttermapStateful({required this.initialCenter, required this.initialZoom});

  @override
  _FluttermapState createState() => _FluttermapState();
}

class _FluttermapState extends State<FluttermapStateful> {
  static _FluttermapState? instance;
  final List<LatLng> _points = [];
  late MapController mapController;
  late CustomLatLng mapCenter;
  late double zoom;

  _FluttermapState() {
    instance = this;
  }

  @override
  void initState() {
    super.initState();
    mapCenter = widget.initialCenter;
    zoom = widget.initialZoom;
    mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        center: mapCenter.toLatLng2(),
        zoom: zoom,
        onTap: (TapPosition, point) {
          addMarker(CustomLatLng(point.latitude, point.longitude));
        },
      ),
      children: [
         VectorTileLayer(
        theme:vtr.ProvidedThemes.lightTheme(),
        tileProviders: TileProviders({
          'openmaptiles': MbTilesVectorTileProvider(
            mbtiles:MbTiles(mbtilesPath: 'C:\\Users\\PEPPINO\\Desktop\\UNIVERSITA\\tesi\\flutter-mmi\\assets\\osm-2020-02-10-v3.11_europe_italy.mbtiles'),),
        }),),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _points,
              color: const Color.fromARGB(255, 0, 0, 0),
              strokeWidth: 3.0,
            ),
          ],
        ),
        MarkerLayer(
          markers: _points.map((point) {
            return Marker(
              width: 80.0,
              height: 80.0,
              point: point,
              child:  const Icon(Icons.location_on_outlined),
            );
          }).toList(),
        ),
      ],
    );
  }

  void addMarker(CustomLatLng l) {
    setState(() {
      _points.add(l.toLatLng2());
      mapCenter = l;
      debugPrint("hai schiacciato $l");
    });
  }

  void deleteAllMarker() {
    setState(() {
      _points.clear();
    });
  }

  void undo1Marker() {
    setState(() {
      if (_points.isNotEmpty) {
        _points.removeLast();
      }
    });
  }

  void movemap(CustomLatLng l) {
    setState(() {
      mapCenter = l;
      mapController.move(l.toLatLng2(), mapController.zoom);
    });
  }

  CustomLatLng getCenter() {
    LatLng center = mapController.center;
    return CustomLatLng(center.latitude, center.longitude);
  }

  void setcontroller() {
    mapController = MapController();
  }

  double getZoom() {
    return mapController.zoom;
  }
}

extension on CustomLatLng {
  LatLng toLatLng2() {
    return LatLng(this.latitude, this.longitude);
  }
}

import 'package:flutter/material.dart';
import 'customlatlong.dart';

abstract class MapInterface {
  Widget buildmap(CustomLatLng l, double z);

  void addMarker(CustomLatLng l);

  void movemap(CustomLatLng l);

  void deleteAllMarker();

  void undo1Marker();

  CustomLatLng getCenter();
  

  void setcontroller();

  double getZoom();
}

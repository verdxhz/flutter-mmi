//l'applicazione parte su windows con mappa flutter online e offline
//parte su android con mappa flutter e google maps, controllare la mappa off
//per web non parte per via della dipendenza di tflite da ffi
import 'dart:io';
import 'package:flutter/material.dart';
import 'offline.dart';
import 'customlatlong.dart';
import 'flutter.dart';
import 'google.dart';
import 'mapInterface.dart';
import 'camera/cameraMain.dart' as cam;

/// Avvia l'applicazione Flutter.
void main() {
  runApp(const MyApp());
}
/// Mantiene il riferimento alla mappa corrente
late MapInterface mapImplementation;
/// Imposta l'applicazione come Stateless, fungendo da base per le schermate successive.
class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 173, 220, 123)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

/// Crea lo stato per la pagina principale dell'applicazione.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

/// Gestisce lo stato della mappa, i controlli dell'interfaccia e le interazioni dell'utente.
class MyHomePageState extends State<MyHomePage> {

  /// Indica se si sta usando Google Map.
  bool _useGoogleMap= false;
  
  /// Indica se si è offline.
  bool _offline = false;
 
  /// Ultima posizione del centro della mappa.
  late CustomLatLng lastCenter;
 
  /// Ultimo livello di zoom della mappa.
  late double lastzoom;
 
  /// Offset della finestra di coordinate.
  Offset _windowOffset = Offset(100, 100);

  /// Indica se la finestra di input delle coordinate è visibile.
  bool _isWindowVisible = false;

  /// Ultima posizione inserita dall'utente.
  late CustomLatLng l;

  /// Controller per il campo di input della latitudine.
  TextEditingController _textFieldController = TextEditingController();

  /// Controller per il campo di input della longitudine.
  TextEditingController _textFieldController1 = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    mapImplementation = (_useGoogleMap
      ? Googlemap()
      : _offline ?
          FluttermapOff()
          :  Fluttermap()) as MapInterface;

    mapImplementation.setcontroller();
    lastCenter = CustomLatLng(40.7128, -74.0060);
    lastzoom = 10.0;
  }

  /// Icone del pollice per l'interruttore della mappa.
  final MaterialStateProperty<Icon?> thumbIcon =
      MaterialStateProperty.resolveWith<Icon?>(
    (Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Icon(Icons.g_mobiledata);
      }
      return const Icon(Icons.facebook);
    },
  );

  @override
  Widget build(BuildContext context) {
    print('$mapImplementation');
    print(_offline);
    return Scaffold(
      body: Stack(
        children: [
          mapImplementation.buildmap(lastCenter, lastzoom),
          Column(
            children: [
              SizedBox(height: Platform.isAndroid ? 30 : 0),
              Row(
                children: [
                  Platform.isAndroid
                      ? Switch(
                          value: _useGoogleMap,
                          onChanged: (value) {
                            cambio(value);
                          },
                          thumbIcon: thumbIcon,
                        )
                      : const SizedBox(),
                  Spacer(),
                  Platform.isAndroid
                      ?const SizedBox() : IconButton(
                      onPressed: () {
                        noWiFi();
                      },
                      icon: _offline ? Icon(Icons.wifi_off) : Icon(Icons.wifi))
                ],
              ),
            ],
          ),
          Container(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () {
                CustomLatLng c = mapImplementation.getCenter();
                mapImplementation
                    .movemap(CustomLatLng(c.latitude, c.longitude + 0.01));
              },
              icon: const Icon(Icons.arrow_right),
              iconSize: 60,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                CustomLatLng c = mapImplementation.getCenter();
                mapImplementation
                    .movemap(CustomLatLng(c.latitude, c.longitude - 0.01));
              },
              icon: const Icon(Icons.arrow_left),
              iconSize: 60,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          Container(
            alignment: Alignment.topCenter,
            child: IconButton(
              onPressed: () {
                CustomLatLng c = mapImplementation.getCenter();
                mapImplementation
                    .movemap(CustomLatLng(c.latitude + 0.01, c.longitude));
              },
              icon: const Icon(Icons.arrow_drop_up),
              iconSize: 60,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            child: IconButton(
              onPressed: () {
                CustomLatLng c = mapImplementation.getCenter();
                mapImplementation
                    .movemap(CustomLatLng(c.latitude - 0.01, c.longitude));
              },
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 60,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          if (_isWindowVisible)
            Positioned(
              left: _windowOffset.dx,
              top: _windowOffset.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _windowOffset += details
                        .delta; //contiene il movimento in termini di distanza
                  });
                },
                child: Material(
                  elevation: 4.0,
                  child: Container(
                    width: 250,
                    height: 200,
                    color: Colors.white,
                    child: Column(
                      children: [
                        Container(
                          height: 30,
                          color: Color.fromARGB(255, 166, 232, 161),
                          child: Center(
                            child: Text(
                              'inserisci le coordinate',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                              child: Column(
                            children: [
                              Text("inserisci latitudine"),
                              TextField(
                                controller: _textFieldController,
                                decoration:
                                    const InputDecoration(hintText: "00.0000"),
                              ),
                              Text("inserisci longitudine"),
                              TextField(
                                controller: _textFieldController1,
                                decoration:
                                    const InputDecoration(hintText: "00.0000"),
                              )
                            ],
                          )),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isWindowVisible = false;
                              l = CustomLatLng(
                                  double.parse(_textFieldController.text),
                                  double.parse(_textFieldController1.text));
                              _textFieldController.clear();
                              _textFieldController1.clear();
                              mapImplementation.movemap(l);
                            });
                          },
                          child: const Text('visita'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isWindowVisible = true;
                });
              },
              child: const Icon(Icons.add),
            ),
          ),
           Column(
            children: [
              SizedBox(height: Platform.isAndroid ? 100 : 40),
              SizedBox(
                height: Platform.isAndroid ? 230 : 150,
                width: Platform.isAndroid ? 140 : 200,//250,
                child: const cam.CameraPage(title: 'tf'),
              ),
            ],
          ),
          info()    
        ],
      ),
    );
  }

  /// Cambia il tipo di mappa in uso.
  void cambio(bool value) {
    setState(() {
      lastCenter = mapImplementation.getCenter();
      lastzoom = mapImplementation.getZoom();
      _useGoogleMap = !_useGoogleMap;
      mapImplementation =
          (_useGoogleMap ? Googlemap() : Fluttermap()) as MapInterface;
      mapImplementation.setcontroller();
    });
  }

  /// Cambia la modalità offline della mappa.
  void noWiFi() {
    setState(() {
      print('map: $_offline');
      lastCenter = mapImplementation.getCenter();
      lastzoom = mapImplementation.getZoom();
      _offline = !_offline;
      print('map1: $_offline');
      mapImplementation = _offline? FluttermapOff()
          : (_useGoogleMap ? Googlemap() : Fluttermap()) as MapInterface;
      mapImplementation.setcontroller();
      
    });
    print('map2: $mapImplementation');
  }
  /// Contolla le gesture sulla mappa.
  actionMap(String gesture) {
    print('gesture: $gesture');
    print('gesture1: $mapImplementation');
    print('map: $_offline');
    switch (gesture) {
      case 'scrolldown':
        CustomLatLng c = mapImplementation.getCenter();
        mapImplementation
            .movemap(CustomLatLng(c.latitude - 0.01, c.longitude));
        break;
      case 'down':
        CustomLatLng c = mapImplementation.getCenter();
        mapImplementation
            .movemap(CustomLatLng(c.latitude + 0.01, c.longitude));
        break;
      case 'left':
        CustomLatLng c = mapImplementation.getCenter();
       mapImplementation
            .movemap(CustomLatLng(c.latitude , c.longitude+ 0.01));
        break;
      case 'right':
        CustomLatLng c = mapImplementation.getCenter();
        mapImplementation
            .movemap(CustomLatLng(c.latitude , c.longitude- 0.01));
        break;
        case 'scrollup':
        CustomLatLng c = mapImplementation.getCenter();
        mapImplementation.addMarker(c);
        break;
    }
  }
  /// Mostra quali sono le gesture supportate dall'applicativo.
  info() {
  final dim=Platform.isAndroid?30.0:50.0;
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(child: SizedBox()),
      Center(
        child: Container(  
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color:Color.fromRGBO(255, 255, 255, 0.5), ),
          width: Platform.isAndroid? 250 : 400,
          child: Column(
            children: [
              Text('Comandi della Mappa'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                  Column(
                    children: [       
                     Image.asset('assets/images/up.png', width: dim, height: dim),
                      const Text('Up'),
                    ],
                  ),
                  SizedBox(width: 15,),
                  Column(
                    children: [
                     Image.asset('assets/images/down.png', width: dim, height: dim),
                      const Text('Down'),
                    ],
                  ),
                  SizedBox(width: 15,),
                  Column(
                    children: [
                      Image.asset('assets/images/r.png', width: dim, height: dim),
                      const Text('Right'),
                    ],
                  ),
                  SizedBox(width: 15,),
                  Column(
                    children: [
                      Image.asset('assets/images/u.png', width: dim, height: dim),
                      const Text('Left'),
                    ],
                  ),
                  SizedBox(width: 15,),
                  Column(
                    children: [
                     Image.asset('assets/images/mark.png', width: dim, height: dim),
                      const Text('Marker'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: Platform.isAndroid? 65: 45,)
    ],
  ); 
  }
  
}

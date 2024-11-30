import 'dart:async';
import 'dart:io';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'helper/gesture_classification_helper.dart';
import 'package:flutter_mmi/main.dart' as map;


//CameraPlatform? _cameraPlatform;
CameraImageData? _latestImage;
GestureClassificationHelper _gestureClassificationHelper= GestureClassificationHelper();
Map<String, double>? _classification;
bool _isProcessing = false;

List<CameraDescription> _cameras = <CameraDescription>[]; // Lista delle fotocamere disponibili.
int _cameraIndex = Platform.isAndroid? 1 : 0; // Indice della fotocamera corrente.
int _cameraId = -1; // ID della fotocamera inizializzata.
bool _initialized = false; // Stato di inizializzazione della fotocamera.
Size? _previewSize; // Dimensioni dell'anteprima.
MediaSettings _mediaSettings = const MediaSettings(
  resolutionPreset: ResolutionPreset.ultraHigh, // Impostazioni della risoluzione.
  fps: 10, // Frame per secondo.
  videoBitrate: 200000, // Bitrate del video. // Bitrate dell'audio.
  enableAudio: false, // Abilitazione dell'audio.
);
StreamSubscription<CameraErrorEvent>? _errorStreamSubscription; // Sottoscrizione agli errori della fotocamera.
StreamSubscription<CameraClosingEvent>? _cameraClosingStreamSubscription; // Sottoscrizione alla chiusura della fotocamera.

class Cameramain extends StatelessWidget {
  const Cameramain({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gesture Classification',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const CameraPage(
        title: 'tf',
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, required this.title});

  final String title;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initHelper();
    });
  }

  Future<void> _initHelper() async {
    try {
      _cameras = await CameraPlatform.instance.availableCameras();
      _gestureClassificationHelper = GestureClassificationHelper();
      await _gestureClassificationHelper.init();
      await _initCamera();
      
      print('Helper initialized');
    } catch (e) {
      print('Error initializing helper: $e');
    }
  }

  Future<void> _initCamera() async {
    // Verifica che la fotocamera non sia già inizializzata.

    if (_cameras.isEmpty) {
      return; // Se non ci sono fotocamere disponibili, esce dal metodo.
    }

    int cameraId = -1; // ID della fotocamera inizializzata.
    try {
      final int cameraIndex = _cameraIndex % _cameras.length; // Calcola l'indice della fotocamera corrente.
      final CameraDescription camera = _cameras[cameraIndex]; // Descrizione della fotocamera corrente.

      cameraId = await CameraPlatform.instance.createCameraWithSettings(
        camera,
        _mediaSettings,
      ); // Crea la fotocamera con le impostazioni specificate.

      unawaited(_errorStreamSubscription?.cancel()); // Annulla la sottoscrizione agli errori della fotocamera.
      _errorStreamSubscription = CameraPlatform.instance
          .onCameraError(cameraId)
          .listen(_onCameraError); // Sottoscrizione agli errori della fotocamera.

      unawaited(_cameraClosingStreamSubscription?.cancel()); // Annulla la sottoscrizione alla chiusura della fotocamera.

      final Future<CameraInitializedEvent> initialized = CameraPlatform.instance
          .onCameraInitialized(cameraId)
          .first; // Evento di inizializzazione della fotocamera.

      await CameraPlatform.instance.initializeCamera(cameraId); // Inizializza la fotocamera.
      final CameraInitializedEvent event = await initialized; // Attende l'evento di inizializzazione.
      _previewSize = Size(event.previewWidth, event.previewHeight); // Ottiene le dimensioni dell'anteprima.

      if (mounted) {
        setState(() {
          _initialized = true; // Aggiorna lo stato di inizializzazione.

          _cameraId = cameraId; // Aggiorna l'ID della fotocamera.
          _cameraIndex = cameraIndex; // Aggiorna l'indice della fotocamera.
        });
      }

      // Aggiunta: Ascolta i dati delle immagini della fotocamera
    CameraPlatform.instance.onStreamedFrameAvailable(_cameraId).listen(
  (CameraImageData? cameraImage) {
    if (cameraImage != null) {
      _imageAnalysis(cameraImage); // Invoca l'analisi dell'immagine
    } else {
      print('Error: Received null CameraImageData');
    }
  },
);

    } on CameraException catch (e) {
      try {
        if (cameraId >= 0) {
          await CameraPlatform.instance.dispose(cameraId); // Rilascia le risorse della fotocamera in caso di errore.
        }
      } on CameraException catch (e) {
        debugPrint('Failed to dispose camera: ${e.code}: ${e.description}'); // Stampa un messaggio di errore.
      }

      // Reset dello stato.
      if (mounted) {
        setState(() {
          _initialized = false; // Resetta lo stato di inizializzazione.
          _cameraId = -1; // Resetta l'ID della fotocamera.
          _cameraIndex = Platform.isAndroid? 1: 0; // Resetta l'indice della fotocamera.
          _previewSize = null; // Resetta le dimensioni dell'anteprima.
          debugPrint('Failed to initialize camera: ${e.code}: ${e.description}'); // Stampa un messaggio di errore.
        });
      }
    }
  }

  Future<void> _imageAnalysis(CameraImageData cameraImage) async {
    // Skip frame if the previous image is still being analyzed
    if (_isProcessing) {
      return;
    }
    print('${cameraImage.height}, ${cameraImage.width}');
    _isProcessing = true;
    _classification = await _gestureClassificationHelper.inferenceCameraFrame(cameraImage);
    action();
    _isProcessing = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _onCameraError(CameraErrorEvent event) {
    if (mounted) {
      _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
          content: Text('Error: ${event.description}'))); // Mostra un messaggio di errore.
    }
  }

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        CameraPlatform.instance.pausePreview(_cameraId);
        print('Image stream stopped');
        break;
      case AppLifecycleState.resumed:
        if (!_isProcessing) {
          CameraPlatform.instance.initializeCamera(_cameraId);
          print('Image stream started');
        }
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CameraPlatform.instance.dispose(_cameraId);
    _gestureClassificationHelper.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('c:$_classification');
    return Scaffold(
      body: Stack(
          children: [
            cameraWidget(context),
            Align(
              heightFactor: 10.0,
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_classification != null)
                      ...(_classification!.entries.toList()
                            ..sort(
                              (a, b) => a.value.compareTo(b.value),
                            ))
                          .reversed
                          .take(1)
                          .map(
                            (e) => Container(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Text(e.key=='down'? 'up': e.key=='scrolldown'? 'down': e.key== 'left'? 'right': e.key=='right'?'left': e.key=='scrollup'? 'mark':''),
                                  const Spacer(),
                                  Text(e.key=='up' || e.key=='leftclick'|| e.key=='rightclick'? '': e.value.toStringAsFixed(2), )
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget cameraWidget(BuildContext context) {

   print('camere:${_cameras.length}');
    return CameraPlatform.instance.buildPreview(_cameraId);
  }

  action(){
    print('action');
    late String gesture;
    if (_classification != null){
      MapEntry<String, double>  first= (_classification!.entries.toList()
                            ..sort(
                              (a, b) => a.value.compareTo(b.value),
                            )).last;
      if(first.value>(first.key=='down'|| first.key=='scrollup'? 0.85 : 0.6)) {
        gesture= first.key;
        map.MyHomePageState().actionMap(gesture);
      }
      else return;
    }
    
  }
}


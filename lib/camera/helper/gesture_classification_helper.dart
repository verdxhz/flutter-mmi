import 'dart:isolate'; // Importa le funzionalità per la creazione e la gestione di isolate.
import 'package:camera_platform_interface/camera_platform_interface.dart'; // Importa l'interfaccia per i dati della fotocamera.
import 'package:flutter/services.dart'; // Importa le funzionalità per la gestione delle risorse di sistema, come i file.
import 'package:tflite_flutter/tflite_flutter.dart'; // Importa la libreria TensorFlow Lite per Flutter.
import 'isolate_inference.dart'; // Importa il file che definisce la logica per l'inferenza in isolate.

class GestureClassificationHelper {
  // Percorso del modello TensorFlow Lite nel progetto.
  static const _modelPath = 'assets/gesture_classification.tflite';
  // Percorso del file con le etichette delle classi.
  static const _labelsPath = 'assets/labels.txt';

  // Lista delle etichette per la classificazione.
  late final List<String> _labels;
  // Interprete per eseguire il modello TensorFlow Lite.
  late Interpreter _interpreter;
  // Oggetto che gestisce l'inferenza in un isolate separato.
  late final IsolateInference _isolateInference;
  // Tensor di input del modello.
  late Tensor _inputTensor;
  // Tensor di output del modello.
  late Tensor _outputTensor;

  // Carica il modello TensorFlow Lite dagli asset.
  Future<void> _loadModel() async {
    // Crea un interprete per il modello caricato dagli asset.
    _interpreter = await Interpreter.fromAsset(_modelPath);
    // Ottiene il tensor di input dal modello.
    _inputTensor = _interpreter.getInputTensors().first;
    // Ottiene il tensor di output dal modello.
    _outputTensor = _interpreter.getOutputTensors().first;
  }

  // Inizializza il modello e le etichette, e avvia l'inferenza in un isolate.
  Future<void> init() async {
    // Carica il modello.
    await _loadModel();
    print('carico le etichette');
    // Carica le etichette delle classi.
    await _loadLabels();
    print('ho caricato le etichette');
    // Crea e avvia l'isolate per l'inferenza.
    _isolateInference = IsolateInference();
    await _isolateInference.start();
  }

  // Carica le etichette delle classi da un file di testo.
 Future<void> _loadLabels() async {
  try {
    print('Attempting to load labels from $_labelsPath');
    //final labelTxt = 
    await rootBundle.loadString(_labelsPath).then((value) => _labels = value.split(','));

    
   // _labels = labelTxt.split(',');
  } catch (e) {
    print('Error loading labels: $e');
  }
}


  // Esegue l'inferenza del modello di classificazione in un isolate separato.
  Future<Map<String, double>> _inference(InferenceModel inferenceModel) async {
    // Crea un oggetto ReceivePort per ricevere i risultati dall'isolate.
    ReceivePort responsePort = ReceivePort();
    // Invia il modello di inferenza all'isolate insieme al port di risposta.
    _isolateInference.sendPort.send(inferenceModel..responsePort = responsePort.sendPort);
    // Attende e ritorna i risultati dell'inferenza.
    var results = await responsePort.first;
    return results;
  }

  // Esegue l'inferenza su un frame dell'immagine della fotocamera.
  Future<Map<String, double>> inferenceCameraFrame(CameraImageData cameraImageData) async {
    // Crea un oggetto InferenceModel con i dati dell'immagine della fotocamera.
    var isolateModel = InferenceModel(cameraImageData, _interpreter.address,
        _labels, _inputTensor.shape, _outputTensor.shape);
    // Esegue l'inferenza e ritorna i risultati.
    return _inference(isolateModel);
  }

  // Chiude l'interprete e l'isolate.
  Future<void> close() async {
    // Chiude l'isolate.
    await _isolateInference.close();
    // Chiude l'interprete del modello.
    _interpreter.close();
  }
}

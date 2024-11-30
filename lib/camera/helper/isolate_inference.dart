import 'dart:io'; // Importa le funzionalità specifiche del sistema operativo.
import 'dart:isolate'; // Importa le funzionalità per la creazione e gestione di isolate.
import 'package:camera_platform_interface/camera_platform_interface.dart'; // Importa l'interfaccia per i dati della fotocamera.
import 'package:image/image.dart' as image_lib; // Importa la libreria per la manipolazione delle immagini.
import '../image_utils.dart'; // Importa la classe per la conversione delle immagini.
import 'package:tflite_flutter/tflite_flutter.dart'; // Importa la libreria TensorFlow Lite per Flutter.

class IsolateInference {
  static const String _debugName = "TFLITE_INFERENCE"; // Nome di debug per l'isolate.
  final ReceivePort _receivePort = ReceivePort(); // Porta per ricevere messaggi dall'isolate.
  late Isolate _isolate; // Riferimento all'isolate.
  late SendPort _sendPort; // Porta per inviare messaggi all'isolate.

  // Getter per ottenere il SendPort dell'isolate.
  SendPort get sendPort => _sendPort;

  // Avvia l'isolate e ottiene il SendPort per comunicare con esso.
  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(entryPoint, _receivePort.sendPort,
        debugName: _debugName);
    _sendPort = await _receivePort.first;
  }

  // Chiude l'isolate e il ReceivePort.
  Future<void> close() async {
    _isolate.kill(); // Termina l'isolate.
    _receivePort.close(); // Chiude il ReceivePort.
  }

  // Punto di ingresso per l'isolate.
  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort(); // Porta per ricevere messaggi all'interno dell'isolate.
    sendPort.send(port.sendPort); // Invia il SendPort al thread principale.

    // Ascolta e gestisce i messaggi in arrivo.
    await for (final InferenceModel isolateModel in port) {
      // Converte l'immagine della fotocamera in formato image_lib.Image.
      image_lib.Image? img = ImageUtils.convertCameraImage(isolateModel.cameraImageData);

      // Capovolge l'immagine perché usiamo la fotocamera frontale.
      image_lib.Image imageInput = image_lib.flip(img!, direction: image_lib.FlipDirection.horizontal);

      // Se siamo su Android, ruota l'immagine di 90 gradi.
      if (Platform.isAndroid) {
        imageInput = image_lib.copyRotate(imageInput, angle: 90);
      }

      // Ridimensiona l'immagine per adattarla alla forma di input del modello.
      imageInput = image_lib.copyResize(
        imageInput,
        width: isolateModel.inputShape[1], // Larghezza dell'immagine di input.
        height: isolateModel.inputShape[2], // Altezza dell'immagine di input.
      );

      // Crea una matrice dei pixel normalizzati per l'input del modello.
      final imageMatrix = List.generate(
        imageInput.height,
        (y) => List.generate(
          imageInput.width,
          (x) {
            final pixel = imageInput.getPixel(x, y);
            // Normalizza i valori dei pixel nell'intervallo [-1, 1].
            return [
              (pixel.b - 127.5) / 127.5,
              (pixel.g - 127.5) / 127.5,
              (pixel.r - 127.5) / 127.5
            ];
          },
        ),
      );

      // Imposta il tensor di input [1, 224, 224, 3].
      final input = [imageMatrix];
      // Imposta il tensor di output [1, 8].
      final output = [List<double>.filled(isolateModel.outputShape[1], 0.0)];
      // Crea un interprete per eseguire il modello.
      Interpreter interpreter = Interpreter.fromAddress(isolateModel.interpreterAddress);
      // Esegue l'inferenza con l'input e memorizza il risultato nell'output.
      interpreter.run(input, output);
      // Ottiene il primo tensor di output.
      final result = output.first;
      // Crea una mappa di classificazione con le etichette e i punteggi.
      var classification = <String, double>{};
      for (var i = 0; i < result.length; i++) {
        // Associa le etichette ai punteggi ottenuti.
        classification[isolateModel.labels[i]] = result[i].toDouble();
      }
      // Invia la mappa di classificazione al thread principale.
      isolateModel.responsePort.send(classification);
    }
  }
}

// Modello di inferenza che contiene i dati necessari per eseguire l'inferenza.
class InferenceModel {
  CameraImageData cameraImageData; // Dati dell'immagine della fotocamera.
  int interpreterAddress; // Indirizzo dell'interprete del modello.
  List<String> labels; // Etichette delle classi.
  List<int> inputShape; // Forma dell'input del modello.
  List<int> outputShape; // Forma dell'output del modello.
  late SendPort responsePort; // Porta per inviare i risultati dell'inferenza.

  // Costruttore per inizializzare il modello di inferenza.
  InferenceModel(this.cameraImageData, this.interpreterAddress, this.labels,
      this.inputShape, this.outputShape);
}

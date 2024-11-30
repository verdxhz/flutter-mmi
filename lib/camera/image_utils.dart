

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:image/image.dart' as image_lib;

// Classe ImageUtils per gestire la conversione dei dati della fotocamera
class ImageUtils {
  // Metodo statico per convertire un oggetto [CameraImageData] in un oggetto [image_lib.Image]
  // Ritorna null se il formato non è supportato
  static image_lib.Image? convertCameraImage(CameraImageData cameraImageData) {
    // Controlla se il formato del gruppo è YUV420 e converte se vero
    if (cameraImageData.format.group == ImageFormatGroup.yuv420) {
      return convertYUV420ToImage(cameraImageData);
    // Altrimenti, controlla se il formato è BGRA8888 e converte se vero
    } else if (cameraImageData.format.group == ImageFormatGroup.bgra8888) {
      return convertBGRA8888ToImage(cameraImageData);
    } else {
      // Ritorna null se il formato non è supportato
      return null;
    }
  }

  // Metodo statico per convertire un [CameraImageData] in formato BGRA8888 in un oggetto [image_lib.Image] in formato RGB
  static image_lib.Image convertBGRA8888ToImage(CameraImageData cameraImageData) {
    // Crea un'immagine con le dimensioni specificate e i dati dei byte nel formato BGRA8888
    image_lib.Image img = image_lib.Image.fromBytes(
        width: cameraImageData.width,//1280, // Larghezza dell'immagine
        height: cameraImageData.height,//720, // Altezza dell'immagine
        bytes: cameraImageData.planes[0].bytes.buffer, // Dati dei byte dell'immagine
        order: image_lib.ChannelOrder.bgra); // Specifica l'ordine dei canali dei colori
    return img; // Ritorna l'immagine convertita
  }

  // Metodo statico per convertire un [CameraImageData] in formato YUV420 in un oggetto [image_lib.Image] in formato RGB
  static image_lib.Image convertYUV420ToImage(CameraImageData cameraImageData) {
    // Ottiene le dimensioni dell'immagine
    final imageWidth = cameraImageData.width;
    final imageHeight = cameraImageData.height;

    // Ottiene i buffer di byte per i piani Y, U e V
    final yBuffer = cameraImageData.planes[0].bytes;
    final uBuffer = cameraImageData.planes[1].bytes;
    final vBuffer = cameraImageData.planes[2].bytes;

    // Ottiene i parametri di stride dei byte e pixel per i piani Y e UV
    final int yRowStride = cameraImageData.planes[0].bytesPerRow;
    final int yPixelStride = cameraImageData.planes[0].bytesPerPixel!;

    final int uvRowStride = cameraImageData.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImageData.planes[1].bytesPerPixel!;

    // Crea un'immagine vuota con le dimensioni specificate
    final image = image_lib.Image(width: imageWidth, height: imageHeight);

    // Cicla attraverso ogni riga dell'immagine
    for (int h = 0; h < imageHeight; h++) {
      // Calcola l'indice UV per la riga corrente
      int uvh = (h / 2).floor();

      // Cicla attraverso ogni colonna dell'immagine
      for (int w = 0; w < imageWidth; w++) {
        // Calcola l'indice UV per la colonna corrente
        int uvw = (w / 2).floor();

        // Calcola l'indice del buffer Y per la posizione corrente
        final yIndex = (h * yRowStride) + (w * yPixelStride);

        // Ottiene il valore Y per il pixel corrente
        final int y = yBuffer[yIndex];

        // Calcola l'indice del buffer UV per la posizione corrente
        final int uvIndex = (uvh * uvRowStride) + (uvw * uvPixelStride);

        // Ottiene i valori U e V per il pixel corrente
        final int u = uBuffer[uvIndex];
        final int v = vBuffer[uvIndex];

        // Calcola i valori RGB utilizzando la formula di conversione
        int r = (y + v * 1436 / 1024 - 179).round();
        int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
        int b = (y + u * 1814 / 1024 - 227).round();

        // Clamps RGB values to ensure they are within the valid range [0, 255]
        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        // Imposta il valore RGB calcolato nel pixel dell'immagine
        image.setPixelRgb(w, h, r, g, b);
      }
    }
    return image; // Ritorna l'immagine convertita
  }
}

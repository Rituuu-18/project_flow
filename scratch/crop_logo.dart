import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/ed-logo.png');
  if (!file.existsSync()) {
    print('File not found!');
    return;
  }
  final original = img.decodePng(file.readAsBytesSync());
  if (original == null) {
    print('Could not decode image.');
    return;
  }

  int minX = original.width;
  int minY = original.height;
  int maxX = 0;
  int maxY = 0;

  for (int y = 0; y < original.height; y++) {
    for (int x = 0; x < original.width; x++) {
      final pixel = original.getPixel(x, y);
      if (pixel.a > 10) { 
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  print('Bounds: $minX, $minY to $maxX, $maxY');
  final cropped = img.copyCrop(original, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);

  // Let's add 20% padding around the longest dimension
  final maxDim = cropped.width > cropped.height ? cropped.width : cropped.height;
  final newSize = (maxDim * 1.2).toInt();
  
  final canvas = img.Image(width: newSize, height: newSize);
  // Fill with solid white color (rgba 255, 255, 255, 255)
  img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));
  
  final dstX = (newSize - cropped.width) ~/ 2;
  final dstY = (newSize - cropped.height) ~/ 2;
  
  img.compositeImage(canvas, cropped, dstX: dstX, dstY: dstY);

  File('assets/ed-logo-cropped.png').writeAsBytesSync(img.encodePng(canvas));
  print('Done! Saved to assets/ed-logo-cropped.png');
}

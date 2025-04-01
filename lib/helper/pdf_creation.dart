// Automatic FlutterFlow imports
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '/flutter_flow/flutter_flow_util.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
//TODO VERSION 1 STABLE

int height = 660 * 2;
int width = 880 * 2;
int quality = 100;
int compressionQuality = 90;

// Modified class to serialize data
class SerializableFile {
  final Uint8List bytes;
  final String name;

  SerializableFile(this.bytes, this.name);

  Map<String, dynamic> toMap() {
    return {'bytes': bytes, 'name': name};
  }

  static SerializableFile fromMap(Map<String, dynamic> map) {
    return SerializableFile(map['bytes'], map['name']);
  }
}

Future<FFUploadedFile> pdfMultiImgWithIsolate(PdfMultiImgParams params) async {
  // Create a ReceivePort for isolate communication
  final receivePort = ReceivePort();

  // Spawn an isolate
  await Isolate.spawn(pdfMultiImg, receivePort.sendPort);

  // Send data to the isolate
  final sendPort = await receivePort.first as SendPort;
  final response = ReceivePort();
  sendPort.send([params.toMap(), response.sendPort]);

  // Wait for the result from the isolate
  final result = await response.first as FFUploadedFile;

  return result;
}

Future<void> pdfMultiImg(SendPort sendPort
    // Nullable parameter for handling landscape images
    ) async {
  final port = ReceivePort();

  sendPort.send(port.sendPort);

  // FlutterIsolate.ensureInitialized()
  await for (final message in port) {
    final params = PdfMultiImgParams.fromMap(message[0]);

    final replyTo = message[1] as SendPort;

    final pdf = pw.Document();

    for (var fileup in params.fileupList) {

      final serializableFile = SerializableFile.fromMap(fileup);



      if(Platform.isAndroid) {

        setCompression(params, serializableFile);
      //
      }

      Uint8List? fileupBytes = resizeAndCompressImage(serializableFile.bytes,
          maxHeight: height , maxWidth:width, quality: quality);

      if (fileupBytes != null) {
        // Decode the image
        var decodedImage = img.decodeImage(Platform.isAndroid ? serializableFile.bytes :fileupBytes);

        if (decodedImage != null) {
          // Check the orientation of the image
          bool isLandscape = decodedImage.width > decodedImage.height;
          img.Image processedImage = decodedImage;

          if (isLandscape && params.selectedIndex == 1) {
            processedImage = img.copyRotate(
              decodedImage,
              angle: 90,
              interpolation: img.Interpolation.nearest,
            );
            // }
          }

          fileupBytes = img.encodeJpg(processedImage,
              quality: compressionQuality); // Reduce quality to 100%

          // Create a MemoryImage from the resized image bytes
          var image = pw.MemoryImage(fileupBytes);

          if (params.selectedIndex == 0) {
            // Add the image as a page in the PDF
            pdf.addPage(pw.Page(
              pageFormat:
                  isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
              margin: pw.EdgeInsets.all(16),
              build: (pw.Context context) {
                if (isLandscape) {
                  // Contain the image and align it to the top of the page
                  return pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Image(image),
                  );
                } else {
                  // Use cover fit for both rotated or portrait images with margins
                  return pw.Container(
                    decoration: pw.BoxDecoration(
                      image: pw.DecorationImage(
                        image: image,
                        fit: pw.BoxFit.contain,
                        alignment: pw.Alignment.center,
                      ),
                    ),
                  );
                }
              },
            ));
          } else if (params.selectedIndex == 1) {
            // Add the image as a page in the PDF
            pdf.addPage(pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.all(16),
              build: (pw.Context context) {
                if (isLandscape) {
                  // Contain the image and align it to the top of the page
                  return pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Image(image),
                  );
                } else {
                  // Use cover fit for both rotated or portrait images with margins
                  return pw.Container(
                    decoration: pw.BoxDecoration(
                      image: pw.DecorationImage(
                        image: image,
                        fit: pw.BoxFit.contain,
                        alignment: pw.Alignment.topCenter,
                      ),
                    ),
                  );
                }
              },
            ));
          } else {
            // Add the image as a page in the PDF
            pdf.addPage(pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.all(16),
              build: (pw.Context context) {
                if (isLandscape) {
                  // Contain the image and align it to the top of the page
                  return pw.Container(
                    alignment: pw.Alignment.topCenter,
                    // Ensure top-center alignment
                    child:
                        pw.Image(image // Scale down to fit the image properly
                            ),
                  );
                } else {
                  // Use cover fit for both rotated or portrait images with margins
                  return pw.Container(
                    alignment: pw.Alignment.topCenter,
                    // Ensure top-center alignment
                    child: pw.Image(
                      image,
                      fit: pw.BoxFit
                          .contain, // Cover the height properly in portrait mode
                    ),
                  );
                }
              },
            ));
          }
          decodedImage = null;
          // image = null;
          await Future.delayed(Duration(milliseconds: 50));

          // Add a small delay to allow garbage collection and avoid memory overload (optimized)
        }
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));

    final Uint8List pdfBytes = await pdf.save();

    await Future.delayed(const Duration(milliseconds: 800));

    print('🔴🔴🔴🔴🔴 ${params.filename}');

    replyTo.send(FFUploadedFile(
      bytes: pdfBytes,
      name: '${params.filename}.pdf',
    ));
  }
}

void setCompression(PdfMultiImgParams params, SerializableFile serializableFile) {

  final image = img.decodeImage(serializableFile.bytes);

  print('🟢🟢🟢🟢🟢 ${image!.height} ${image.width}');

  if(image.height < 1162 || image.width<1483) {

    if(image.height <728 || image.width < 1015) {

      compressionQuality = 100;

    } else {

      compressionQuality = 85;

    }

    return;

  }

  switch (params.selectedValue) {

    case 'High':


      height = 1080;
      width = 1920;
      quality = 100;
      compressionQuality = 20;

      break;
    case 'Low':

      height = 1080;
      width = 1920;
      quality = 100;
      compressionQuality = 1;

      break;
    case 'Medium':

      height = (1080 * 0.75).toInt();
      width = (1920 * 0.75).toInt();
      quality = 100;
      compressionQuality = 5;

      break;
    default:

      height = 1080;
      width = 1920;
      quality = 100;
      compressionQuality = 20;

      break;
  }

}

/// Resize and compress an image while maintaining aspect ratio
Uint8List resizeAndCompressImage(
  Uint8List imageBytes, {
  int maxWidth = 800,
  int maxHeight = 800,
  int quality = 70,
}) {
  // Decode the image
  final img.Image? image = img.decodeImage(imageBytes);
  if (image == null) return imageBytes; // Return original if decoding fails

  // Get original dimensions
  int originalWidth = image.width;
  int originalHeight = image.height;

  // Calculate new dimensions while maintaining aspect ratio
  double aspectRatio = originalWidth / originalHeight;
  int newWidth = originalWidth;
  int newHeight = originalHeight;

  if (newWidth > maxWidth) {
    newWidth = maxWidth;
    newHeight = (newWidth / aspectRatio).round();
  }
  if (newHeight > maxHeight) {
    newHeight = maxHeight;
    newWidth = (newHeight * aspectRatio).round();
  }

  // Resize the image
  final img.Image resized =
      img.copyResize(image, width: newWidth, height: newHeight);

  // Compress the image (JPG format)
  return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
}

Future<Uint8List?> compressImageBytes(Uint8List imageBytes, {int quality = 85}) async {
  return await FlutterImageCompress.compressWithList(
    imageBytes,
    quality: quality, // Adjust quality (85 is a good balance)
    // format: CompressFormat.jpeg, // Change format if needed (jpeg/png/webp)
  );
}
//todo using isolate

// Define a parameter class for isolate communication
class PdfMultiImgParams {
  final List<Map<String, dynamic>> fileupList; // Use serialized form
  final String filename;
  // final String? notes;
  // final bool isFirstPageSelected;
  final String? selectedValue;
  final int? selectedIndex;

  PdfMultiImgParams({
    required this.fileupList,
    required this.filename,
    this.selectedIndex, this.selectedValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileupList': fileupList,
      'filename': filename,
      'selectedIndex': selectedIndex,
      'selectedValue': selectedValue,
    };
  }

  static PdfMultiImgParams fromMap(Map<String, dynamic> map) {
    return PdfMultiImgParams(
      fileupList: List<Map<String, dynamic>>.from(map['fileupList']),
      filename: map['filename'],
      selectedIndex: map['selectedIndex'],
      selectedValue: map['selectedValue'],
    );
  }
}

// void showErrorAlert(BuildContext context, String title, String message) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: Text(title, style: TextStyle(color: Colors.red)),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(); // Close the dialog
//             },
//             child: Text('OK'),
//           ),
//         ],
//       );
//     },
//   );
// }

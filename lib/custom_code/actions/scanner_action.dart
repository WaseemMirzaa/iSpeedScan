// Automatic FlutterFlow imports
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!
import 'package:ispeedscan/helper/shared_preference_service.dart';
import 'package:ispeedscan/helper/pdf_creation.dart'; // Imports other custom actions
import 'dart:convert';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import '../../../helper/analytics_helper.dart';

Future<List<String>> scannerAction(BuildContext context) async {
  List<String> _pictures = [];
  List<String> pictures = [];
  String resultMessage = '';

  var analytics = FirebaseAnalytics.instance;

  var isPhotoMode = await PreferenceService.getMode();

  try {
    pictures = await CunningDocumentScanner.getPictures(
            noOfPages: 60, isGalleryImportAllowed: false) ??
        [];
    _pictures = pictures;

    // Log scan completed event
    await AnalyticsHelper.logScanCompleted(pictures.length);
  } catch (exception) {
    // Handle exception here
    throw exception;

    return pictures;
  }

  // For Android 10+ (API 29+), use MediaStore API
  if (isPhotoMode && Platform.isAndroid) {
    for (String picture in pictures) {
      final time = DateTime.now()
          .toIso8601String()
          .replaceAll('.', '-')
          .replaceAll(':', '-');

      String name = 'ispeedscan$time.jpg';

      // TODO: Implement alternative image saving method
      // await ImageGallerySaver.saveFile(picture, name: name);
      print('Would save image: $name at $picture');
    }
  }
  // For iOS, the existing code works fine
  else if (isPhotoMode && Platform.isIOS) {
    for (String picture in pictures) {
      final time = DateTime.now()
          .toIso8601String()
          .replaceAll('.', '-')
          .replaceAll(':', '-');

      String name = 'ispeedscan$time.pdf';
      // TODO: Implement alternative image saving method
      // await ImageGallerySaver.saveFile(picture, name: name);
      print('Would save image: $name at $picture');
    }
  }
  if (isPhotoMode) {
    await analytics.logEvent(
      name: 'event_on_pictures_saved',
      parameters: {
        'os': Platform.isAndroid ? 'android' : 'ios',
        'photoMode': isPhotoMode! ? "true" : "false",
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  return pictures;
}

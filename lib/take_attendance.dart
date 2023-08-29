import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_exif_plugin/tags.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_exif_plugin/flutter_exif_plugin.dart';

import 'image_details_page.dart';

class TakeAttendance extends StatefulWidget {
  const TakeAttendance({super.key});

  @override
  State<TakeAttendance> createState() => _TakeAttendanceState();
}

class _TakeAttendanceState extends State<TakeAttendance> {
  File? _pickedImage;
  Position? _currentPosition;
  FlutterExif? _exif;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Geotag App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _displayedImage(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick or Capture Image'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _displayedImage() {
    return Column(
      children: <Widget>[
        _pickedImage != null
            ? GestureDetector(
                onTap: () {
                  if (_pickedImage != null) {
                    _navigateToImageDetails(
                        _pickedImage!.path, _pickedImage!.readAsBytesSync());
                  }
                },
                child: Image.file(
                  _pickedImage!,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              )
            : Container(),
        const SizedBox(height: 10),
        _currentPosition != null
            ? Column(
                children: [
                  Text(
                    'Geotag: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Unix Timestamp: ${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              )
            : Container(),
      ],
    );
  }

  void _pickImage() async {
    // Pick image from gallery or capture from camera
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery, // Change to ImageSource.camera for capturing
    );

    if (pickedImage != null) {
      setState(() {
        _pickedImage = File(pickedImage.path);
      });

      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          // Request permission if denied
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.denied) {
          _showLocationPermissionError();
        } else {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          setState(() {
            _currentPosition = position;
          });

          // Geotag the image using EXIF data
          await _geotagImage(position);
        }
      } catch (e) {
        // Handle location permission exception
        print("Error getting location: $e");
        _showLocationPermissionError();
      }
    }
  }

  Future<void> _geotagImage(Position position) async {
    if (_pickedImage != null) {
      final latitude = position.latitude;
      final longitude = position.longitude;
      final unixTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      _exif = FlutterExif.fromPath(_pickedImage!.path);
      await _exif!.setLatLong(latitude, longitude);
      await _exif!
          .setAttribute(TAG_USER_COMMENT, 'Unix Timestamp: $unixTimestamp');
      await _exif!.saveAttributes();
    }
  }

  void _showLocationPermissionError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Please enable location permissions in your device settings to use geotagging functionality.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Open app settings to allow user to enable permissions
              Geolocator.openAppSettings();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToImageDetails(String imagePath, Uint8List imageBytes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageDetailsPage(
          imagePath: imagePath,
          imageBytes: imageBytes,
        ),
      ),
    );
  }
}

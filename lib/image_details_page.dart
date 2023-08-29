import 'package:flutter/material.dart';
import 'package:flutter_exif_plugin/flutter_exif_plugin.dart';
import 'dart:typed_data';

import 'package:flutter_exif_plugin/tags.dart';

class ImageDetailsPage extends StatefulWidget {
  final String imagePath;
  final Uint8List imageBytes;

  const ImageDetailsPage({super.key,
    required this.imagePath,
    required this.imageBytes,
  });

  @override
  _ImageDetailsPageState createState() => _ImageDetailsPageState();
}

class _ImageDetailsPageState extends State<ImageDetailsPage> {
  FlutterExif? _exif;
  String _exifData = '';

  @override
  void initState() {
    super.initState();
    _readExifData();
  }

  Future<void> _readExifData() async {
    _exif = FlutterExif.fromBytes(widget.imageBytes);
    final result = await _exif!.getAttribute(TAG_USER_COMMENT);
    final latlon = await _exif!.getLatLong();

    final StringBuffer exifDataBuffer = StringBuffer();
    exifDataBuffer.writeln('User Comment: $result');
    exifDataBuffer.writeln('Latitude: ${latlon?.first}');
    exifDataBuffer.writeln('Longitude: ${latlon?.last}');

    setState(() {
      _exifData = exifDataBuffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.memory(
              widget.imageBytes,
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            const Text(
              'EXIF Data:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(_exifData),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:universal_html/html.dart' as html;

void main() {
  runApp(CaesiumApp());
}

class CaesiumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caesium Lite Web',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: WebHomePage(),
    );
  }
}

class WebHomePage extends StatefulWidget {
  @override
  _WebHomePageState createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  List<Uint8List> selectedImages = [];
  List<Uint8List> compressedImages = [];
  double quality = 80;
  String status = 'Готово';

  Future<void> pickImages() async {
    final files = await openFiles(acceptedTypeGroups: [
      const XTypeGroup('images', extensions: ['jpg', 'jpeg', 'png'])
    ], multiple: true);

    if (files.isEmpty) return;

    final bytesList = <Uint8List>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      bytesList.add(bytes);
    }

    setState(() {
      selectedImages = bytesList;
      compressedImages.clear();
      status = 'Выбрано: ${selectedImages.length} фото';
    });
  }

  Future<void> compressAll() async {
    if (selectedImages.isEmpty) return;

    setState(() {
      status = 'Сжимаем...';
      compressedImages.clear();
    });

    try {
      for (var originalBytes in selectedImages) {
        final result = await FlutterImageCompress.compressWithList(
          originalBytes,
          quality: quality.toInt(),
        );
        compressedImages.add(Uint8List.fromList(result));
      }
      setState(() {
        status = 'Готово! Сжато: ${compressedImages.length} фото';
      });
    } catch (e) {
      setState(() {
        status = 'Ошибка: $e';
      });
    }
  }

  void downloadAll() {
    if (compressedImages.isEmpty) return;

    for (int i = 0; i < compressedImages.length; i++) {
      final blob = html.Blob([compressedImages[i]], 'image/jpeg');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..download = 'compressed_${DateTime.now().millisecondsSinceEpoch}_$i.jpg'
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Caesium Lite Web'),
        centerTitle: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: pickImages,
              icon: Icon(Icons.add_photo_alternate),
              label: Text('Выбрать фото'),
            ),
            SizedBox(height: 16),
            if (selectedImages.isNotEmpty)
              Text('${selectedImages.length} выбрано', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            Text('Качество: ${quality.toInt()}%'),
            Slider(
              value: quality,
              min: 1,
              max: 100,
              divisions: 99,
              label: '${quality.toInt()}%',
              onChanged: (value) {
                setState(() {
                  quality = value;
                });
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: compressAll,
              child: Text('Сжать все фото'),
            ),
            SizedBox(height: 16),
            Text(status, style: TextStyle(fontSize: 14, color: Colors.blue), textAlign: TextAlign.center),
            SizedBox(height: 16),
            if (compressedImages.isNotEmpty)
              ElevatedButton.icon(
                onPressed: downloadAll,
                icon: Icon(Icons.download),
                label: Text('Скачать все'),
              ),
          ],
        ),
      ),
    );
  }
}

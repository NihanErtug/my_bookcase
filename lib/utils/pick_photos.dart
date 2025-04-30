import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PickPhotos extends StatefulWidget {
  final Function(String path) onImagePicked;
  const PickPhotos({super.key, required this.onImagePicked});

  @override
  State<PickPhotos> createState() => _PickPhotosState();
}

class _PickPhotosState extends State<PickPhotos> {
  String? _imagePath;

  Future<String?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final String newPath =
            p.join(directory.path, p.basename(pickedFile.path));
        final File newImage = await File(pickedFile.path).copy(newPath);

        return newImage.path;
      } catch (e) {
        print("Dosya Kopyalanırken Hata: $e");
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_imagePath != null)
          Image.file(
            File(_imagePath!),
            height: 150,
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
                icon: Icon(Icons.photo),
                label: Text("Galeriden"),
                onPressed: () async {
                  final path = await pickImage(ImageSource.gallery);
                  if (path != null) {
                    setState(() {
                      _imagePath = path;
                    });

                    widget.onImagePicked(path);

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "Bu fotoğraf sadece bu cihazda görüntülenebilir.")));
                  }
                }),
            const SizedBox(width: 16),
            ElevatedButton.icon(
                onPressed: () async {
                  final path = await pickImage(ImageSource.camera);
                  if (path != null) {
                    setState(() {
                      _imagePath = path;
                    });

                    widget.onImagePicked(path);

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "Bu fotoğraf sadece bu cihazda görüntülenebilir.")));
                  }
                },
                icon: Icon(Icons.camera_alt),
                label: Text("Kameradan")),
          ],
        ),
      ],
    );
  }
}

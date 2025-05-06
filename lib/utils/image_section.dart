import 'dart:io';

import 'package:bookcase/utils/pick_photos.dart';
import 'package:flutter/material.dart';

class ImageSection extends StatefulWidget {
  final TextEditingController controller;

  const ImageSection({super.key, required this.controller});

  @override
  State<ImageSection> createState() => _ImageSectionState();
}

class _ImageSectionState extends State<ImageSection> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  bool isUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Widget buildImagePreview(String path) {
    if (isUrl(path)) {
      return Image.network(
        path,
        height: 200,
        width: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorContainer('Geçersiz URL');
        },
      );
    } else {
      final file = File(path);
      if (!file.existsSync()) {
        return _buildErrorContainer("Dosya bulunamadı");
      }
      return Image.file(
        file,
        height: 200,
        width: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorContainer("Resim yüklenemedi");
        },
      );
    }
  }

  Widget _buildErrorContainer(String message) {
    return Container(
      color: Colors.grey.shade200,
      width: 150,
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.controller.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("Kapak Fotoğrafı", style: TextStyle(fontSize: 16)),
        Divider(),
        SizedBox(height: 10),
        if (imagePath.isNotEmpty)
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: buildImagePreview(imagePath),
              ),
              TextButton.icon(
                  onPressed: () async {
                    final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: Text("Fotoğrafı Sil"),
                              content: Text(
                                  "Bu fotoğrafı silmek istediğinizden emin misiniz?"),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text("İptal")),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      "Sil",
                                      style: TextStyle(color: Colors.redAccent),
                                    )),
                              ],
                            ));
                    if (shouldDelete == true) {
                      widget.controller.clear();
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "Silme işleminin tamalanması için 'Kaydet' e basmayı unutmayın.")));
                  },
                  icon: Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                  ),
                  label: Text("Fotoğrafı Sil",
                      style: TextStyle(color: Colors.redAccent))),
            ],
          )
        else
          Text("Fotoğraf Seçilmedi."),
        SizedBox(height: 10),
        ElevatedButton.icon(
            onPressed: () async {
              final imagePath = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PickPhotos(
                          onImagePicked: (path) =>
                              Navigator.pop(context, path))));
              if (imagePath != null) {
                widget.controller.text = imagePath;
              }
            },
            icon: Icon(Icons.photo),
            label: Text("Fotoğraf Seç")),
      ],
    );
  }
}

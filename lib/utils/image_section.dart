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
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("Kapak Fotoğrafı", style: TextStyle(fontSize: 16)),
        Divider(),
        SizedBox(height: 10),
        if (widget.controller.text.isNotEmpty)
          Column(
            children: [
              Image.file(
                File(widget.controller.text),
                height: 200,
                fit: BoxFit.cover,
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

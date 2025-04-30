import 'package:flutter/material.dart';

Widget buildPopupMenuButton({
  required BuildContext context,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  IconData icon = Icons.more_vert,
}) {
  return PopupMenuButton<String>(
      icon: Icon(icon),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text("Düzenle"),
                ],
              )),
          const PopupMenuDivider(),
          PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18),
                  SizedBox(width: 8),
                  Text("Sil"),
                ],
              )),
        ];
      });
}

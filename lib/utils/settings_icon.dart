import 'package:bookcase/themes/theme_switch_button.dart';
import 'package:flutter/material.dart';

Widget buildSettingsPopupMenuButton(
    {IconData icon = Icons.settings,
    required VoidCallback onTheme,
    required VoidCallback onLogout,
    required VoidCallback onSettings}) {
  return PopupMenuButton<String>(
      icon: Icon(icon),
      onSelected: (value) {
        if (value == 'logout') {
          onLogout();
        } else if (value == 'settings') {
          onSettings();
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
              enabled: false,
              child: Column(
                children: [
                  const Text(
                    "Tema Değiştir",
                  ),
                  Transform.scale(scale: 0.7, child: ThemeSwitchButton()),
                ],
              )),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 18),
                  SizedBox(width: 8),
                  Text("Ayarlar")
                ],
              )),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text("Çıkış Yap")
                ],
              )),
        ];
      });
}

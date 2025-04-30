import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  Future<void> toggleTheme(ThemeMode themeMode) async {
    state = themeMode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeMode.toString());
  }

  Future<void> loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString =
        prefs.getString('themeMode') ?? ThemeMode.system.toString();
    state = ThemeMode.values.firstWhere((e) => e.toString() == themeModeString,
        orElse: () => ThemeMode.system);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) {
    final notifier = ThemeNotifier();
    notifier.loadThemePreferences();
    return notifier;
  },
);

class FontSettingsNotifier extends StateNotifier<FontSettings> {
  FontSettingsNotifier()
      : super(FontSettings(fontFamily: 'Roboto', fontSize: 16.0));

  void changeFontFamily(String newFamily) {
    state = state.copyWith(fontFamily: newFamily);
  }

  void increaseFontSize() {
    state = state.copyWith(fontSize: state.fontSize + 1.0);
  }

  void decreaseFontSize() {
    if (state.fontSize > 12.0) {
      state = state.copyWith(fontSize: state.fontSize - 1.0);
    }
  }
}

@immutable
class FontSettings {
  final String fontFamily;
  final double fontSize;

  const FontSettings({required this.fontFamily, required this.fontSize});

  FontSettings copyWith({
    String? fontFamily,
    double? fontSize,
  }) {
    return FontSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

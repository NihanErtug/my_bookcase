import 'package:bookcase/providers/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ThemeModeOption { light, dark }

class ThemeSwitchButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    final selectedTheme = themeMode == ThemeMode.light
        ? ThemeModeOption.light
        : ThemeModeOption.dark;

    return SegmentedButton<ThemeModeOption>(
        style: SegmentedButton.styleFrom(
          padding: EdgeInsets.all(5),
          side: BorderSide(width: 1, color: Colors.deepPurple),
          selectedBackgroundColor: const Color.fromARGB(255, 135, 96, 241),
        ),
        segments: const [
          ButtonSegment(
              value: ThemeModeOption.light,
              icon: Icon(Icons.light_mode),
              label: Text('Açık')),
          ButtonSegment(
            value: ThemeModeOption.dark,
            label: Text("Koyu"),
            icon: Icon(Icons.dark_mode),
          ),
        ],
        selected: {selectedTheme},
        onSelectionChanged: (Set<ThemeModeOption> newSelection) {
          final selected = newSelection.first;
          switch (selected) {
            case ThemeModeOption.light:
              ref.read(themeProvider.notifier).toggleTheme(ThemeMode.light);
              break;
            case ThemeModeOption.dark:
              ref.read(themeProvider.notifier).toggleTheme(ThemeMode.dark);
              break;
          }
        });
  }
}

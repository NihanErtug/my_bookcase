import 'package:bookcase/firebase_options.dart';
import 'package:bookcase/providers/firebase_service_provider.dart';
import 'package:bookcase/providers/theme_notifier.dart';
import 'package:bookcase/screens/login_register_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(child: const MyBookcaseApp()));
}

class MyBookcaseApp extends ConsumerWidget {
  const MyBookcaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final fontSettings = ref.watch(fontSettingsProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Bookcase',
      theme: ThemeData.light().copyWith(
        textTheme: ThemeData.light()
            .textTheme
            .apply(fontFamily: fontSettings.fontFamily),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: LoginRegisterPage(),
    );
  }
}

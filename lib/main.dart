import 'package:flutter/material.dart';

import 'features/nfc_ekyc/presentation/nfc_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NfcEkycDemoApp());
}

class NfcEkycDemoApp extends StatelessWidget {
  const NfcEkycDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC eKYC Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006C68)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const NfcHomeScreen(),
    );
  }
}

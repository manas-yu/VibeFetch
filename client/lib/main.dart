import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/screens/home_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request permissions on app start
  await _requestPermissions();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _requestPermissions() async {
  // Request microphone permission
  await Permission.microphone.request();

  // Request storage permission
  await Permission.storage.request();

  // For Android 13+ (API 33+), request specific media permissions
  if (await Permission.photos.isDenied) {
    await Permission.photos.request();
  }

  if (await Permission.videos.isDenied) {
    await Permission.videos.request();
  }

  if (await Permission.audio.isDenied) {
    await Permission.audio.request();
  }

  // Note: System audio recording permission is handled by the SystemAudioRecorder plugin
  // when SystemAudioRecorder.requestRecord() is called
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Shazam',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

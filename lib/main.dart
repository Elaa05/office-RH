import 'package:attendancewithqr/screen/scan_qr_page.dart';
import 'package:attendancewithqr/translate/translate.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: main_title,
      theme: ThemeData(
        primarySwatch: Colors.grey,
        primaryColor: Color(0xFF3f6ae0),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ScanQrPage(),
    );
  }
}

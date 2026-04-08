import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/pos_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasir Cafe',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: PosPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

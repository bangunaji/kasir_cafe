import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn.instance.initialize();
  
  // Initialize Hive for Multi-tenant support
  await Hive.initFlutter();
  await Hive.openBox('settings');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final AuthBloc? authBloc;
  const MyApp({super.key, this.authBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => authBloc ?? (AuthBloc()..add(CheckAuthStatus())),
      child: MaterialApp(
        title: 'Kasir Cafe',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: const LoginPage(), // LoginPage handles all redirection logic via BlocListener
      ),
    );
  }
}


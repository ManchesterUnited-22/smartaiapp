import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:todolist_app/core/providers/theme_provider.dart';
import 'package:todolist_app/core/services/notification_service.dart';
import 'package:todolist_app/core/theme/app_theme.dart';
import 'package:todolist_app/features/ai_engine/domain/usecases/route_message.dart';
import 'package:todolist_app/features/chat/presentation/providers/chat_provider.dart';

import 'package:todolist_app/features/tasks/presentation/screens/home_screen.dart';
import 'firebase_options.dart';
import 'injection/injection_container.dart';
import 'core/services/auth_services.dart';
import 'features/auth/presentation/screens/login_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final notificationService = NotificationService();
  await notificationService.initialize();
  runApp(
    MultiProvider(
      providers: appProviders,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Consumer<ThemeProvider>
    (builder: (context, themeProvider, _)
     {
      return MaterialApp(
        title: 'AI Life Companion',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeProvider.themeMode,
        home: StreamBuilder<User?>(
          stream: context.read<AuthService>().authStateChanges,
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          context.read<ChatProvider>().reset();
          context.read<RouteMessage>().reset();
          return const LoginScreen();
        },
      ),
    );
  }
    );
}}
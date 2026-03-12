import 'package:flutter/material.dart';
import 'package:smart_home_project/features/presentation/landing_screen.dart';
import 'package:smart_home_project/features/presentation/initial_screen.dart';
import 'package:smart_home_project/features/presentation/login_screen.dart';
import 'package:smart_home_project/features/presentation/signup_screen.dart';
import 'package:smart_home_project/features/presentation/home_screen.dart'; // ← add this

class AppRouter {
  static const String landing = '/landing';
  static const String initialRoute = '/initial';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  static final Map<String, WidgetBuilder> routes = {
    landing: (context) => const LandingScreen(),
    initialRoute: (context) => const InitialScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const SignUpScreen(),
    home: (context) => const HomePage(), // ← change this
  };
}
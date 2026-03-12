import 'package:flutter/material.dart';
import 'package:smart_home_project/navigation/app_router.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF13192A), Color(0xFF0D1018)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.home_outlined,
                      size: 100,
                      color: Color(0xFF3DE8C4),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              const Text(
                'SMART LIVING · REIMAGINED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                  color: Color(0xFF3DE8C4),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Control Your',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: Color(0xFFE8EAF0),
                ),
              ),
              const Text(
                'Home.',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: Color(0xFF3DE8C4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Comfort, convenience, and peace of mind —\nall from one intelligent app.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.65,
                  color: Color(0xFF8090A8),
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.initialRoute);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DE8C4),
                    foregroundColor: const Color(0xFF071A16),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
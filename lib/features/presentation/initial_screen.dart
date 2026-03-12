import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_home_project/navigation/app_router.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _googleLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRouter.home, (_) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e',
                style: const TextStyle(color: Color(0xFFE8EAF0))),
            backgroundColor: const Color(0xFF1E2530),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF111318),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E2530)),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  color: Color(0xFF3DE8C4),
                  size: 28,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                  color: Color(0xFF8090A8),
                ),
              ),
              const Text(
                'Smart Home.',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: Color(0xFFE8EAF0),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Manage your home, devices, and energy\nall from one place.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.65,
                  color: Color(0xFF5A6070),
                ),
              ),
              const Spacer(flex: 3),

              // ── Login Button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.login);
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
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Create Account Button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.register);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111318),
                    foregroundColor: const Color(0xFFE8EAF0),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFF1E2530)),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create an Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Divider ──
              Row(
                children: const [
                  Expanded(child: Divider(color: Color(0xFF1E2530))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5A6070)),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFF1E2530))),
                ],
              ),
              const SizedBox(height: 20),

              // ── Google Sign-In Button ──
              SizedBox(
                width: double.infinity,
                child: _googleLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3DE8C4),
                          strokeWidth: 2.5,
                        ),
                      )
                    : OutlinedButton(
                        onPressed: _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF111318),
                          side: const BorderSide(color: Color(0xFF1E2530)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://www.google.com/favicon.ico',
                              width: 20,
                              height: 20,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.g_mobiledata,
                                color: Color(0xFF4285F4),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFE8EAF0),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const Spacer(flex: 2),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'By continuing you agree to our ',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF5A6070),
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms',
                        style: const TextStyle(color: Color(0xFF3DE8C4)),
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(color: Color(0xFF3DE8C4)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
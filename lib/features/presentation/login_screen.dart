import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'otp_screen.dart';

// ─── Shared Design Tokens ─────────────────────────────────
const kBg       = Color(0xFF0A0C10);
const kCard     = Color(0xFF111318);
const kBorder   = Color(0xFF1E2530);
const kAccent   = Color(0xFF3DE8C4);
const kTextMain = Color(0xFFE8EAF0);
const kTextSub  = Color(0xFF8090A8);
const kTextMute = Color(0xFF5A6070);
const kDark     = Color(0xFF071A16);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey         = GlobalKey<FormState>();
  final _emailCtrl       = TextEditingController();
  final _mobileCtrl      = TextEditingController();
  final _passwordCtrl    = TextEditingController();

  bool _obscurePassword  = true;
  bool _rememberMe       = false;
  bool _loading          = false;
  bool _googleLoading    = false;
  int  _selectedTab      = 0; // 0=Email  1=Mobile

  // Country code state
  String _countryCode    = '+91';
  String _countryFlag    = '🇮🇳';

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Switch tab with fade ──
  void _switchTab(int i) {
    if (i == _selectedTab) return;
    _fadeCtrl.reverse().then((_) {
      setState(() => _selectedTab = i);
      _fadeCtrl.forward();
    });
  }

  // ── Google Sign-In (google_sign_in v6.x) ──
 Future<void> _signInWithGoogle() async {
  debugPrint('>>> Google Sign-In: button tapped');
  setState(() => _googleLoading = true);
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    debugPrint('>>> Google Sign-In: calling signIn()');
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    debugPrint('>>> Google Sign-In: result = $googleUser');

    if (googleUser == null) {
      setState(() => _googleLoading = false);
      return;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
    if (mounted) _goHome();
  } catch (e, stack) {
    debugPrint('>>> Google Sign-In ERROR: $e');
    debugPrint('>>> Stack: $stack');
    _showError('Google Sign-In failed: $e');
  } finally {
    if (mounted) setState(() => _googleLoading = false);
  }
}
  // ── Send OTP via Firebase ──
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final phone = '$_countryCode${_mobileCtrl.text.trim()}';

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) _goHome();
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _loading = false);
        _showError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() => _loading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              phoneNumber: phone,
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // ── Email login ──
  Future<void> _emailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) _goHome();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: kTextMain)),
        backgroundColor: const Color(0xFF1E2530),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('>>> build: _googleLoading=$_googleLoading, _loading=$_loading');
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kTextMain, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Heading ──
                const Text('Welcome',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, height: 1.1, color: kTextSub)),
                const Text('back.',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1.2, color: kTextMain)),

                const SizedBox(height: 36),

                // ── Tab Switcher ──
                _TabSwitcher(
                  selected: _selectedTab,
                  labels: const ['Email', 'Mobile number'],
                  onTap: _switchTab,
                ),

                const SizedBox(height: 28),

                // ── Fields (fade on switch) ──
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _selectedTab == 0 ? _emailFields() : _mobileField(),
                ),

                const SizedBox(height: 40),

                // ── CTA Button ──
                _loading
                    ? const Center(child: CircularProgressIndicator(color: kAccent))
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedTab == 1 ? _sendOtp : _emailLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccent,
                            foregroundColor: kDark,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                          child: Text(
                            _selectedTab == 1 ? 'Send OTP' : 'Login',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                          ),
                        ),
                      ),

                const SizedBox(height: 24),

                // ── Divider with "or" ──
                Row(
                  children: [
                    Expanded(child: Divider(color: kBorder, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or', style: TextStyle(color: kTextMute, fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: kBorder, thickness: 1)),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Google Sign-In Button ──
                _googleLoading
                    ? const Center(child: CircularProgressIndicator(color: kAccent))
                    : SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: kBorder, width: 1.5),
                            backgroundColor: kCard,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google "G" logo drawn with colored text
                              _GoogleLogo(),
                              const SizedBox(width: 12),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: kTextMain,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                const SizedBox(height: 20),

                // ── Sign up ──
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(fontSize: 13, color: kTextMute),
                        children: [TextSpan(text: 'Sign up', style: TextStyle(color: kAccent, fontWeight: FontWeight.w600))],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Email + Password fields ──
  Widget _emailFields() {
    return Column(
      children: [
        _VField(
          controller: _emailCtrl,
          label: 'Email Address',
          hint: 'john@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your email';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _VField(
          controller: _passwordCtrl,
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: kTextMute, size: 20),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your password';
            if (v.length < 8) return 'Min 8 characters';
            return null;
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: _rememberMe ? kAccent : kCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _rememberMe ? kAccent : kBorder),
                  ),
                  child: _rememberMe ? const Icon(Icons.check, size: 14, color: kDark) : null,
                ),
                const SizedBox(width: 8),
                const Text('Remember me', style: TextStyle(fontSize: 12, color: kTextMute)),
              ]),
            ),
            const Text('Forgot Password?', style: TextStyle(fontSize: 12, color: kAccent, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  // ── Mobile field with country code ──
  Widget _mobileField() {
    return _VField(
      controller: _mobileCtrl,
      label: 'Mobile number',
      hint: '00000 00000',
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      prefixWidget: GestureDetector(
        onTap: _showCountryPicker,
        child: Container(
          margin: const EdgeInsets.only(left: 14, right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_countryFlag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(_countryCode,
                  style: const TextStyle(color: kTextSub, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, color: kTextMute, size: 18),
              const SizedBox(width: 10),
              Container(width: 1, height: 20, color: kBorder),
            ],
          ),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter your mobile number';
        if (v.length < 10) return 'Enter a valid 10-digit number';
        return null;
      },
    );
  }

  // ── Country picker bottom sheet ──
  void _showCountryPicker() {
    final countries = [
      ('🇮🇳', '+91', 'India'),
      ('🇺🇸', '+1', 'USA'),
      ('🇬🇧', '+44', 'UK'),
      ('🇦🇺', '+61', 'Australia'),
      ('🇸🇬', '+65', 'Singapore'),
      ('🇦🇪', '+971', 'UAE'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14171F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Country', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextMain)),
            const SizedBox(height: 16),
            ...countries.map((c) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(c.$1, style: const TextStyle(fontSize: 24)),
              title: Text(c.$3, style: const TextStyle(color: kTextMain, fontSize: 14)),
              trailing: Text(c.$2, style: const TextStyle(color: kTextSub, fontSize: 13)),
              onTap: () {
                setState(() { _countryFlag = c.$1; _countryCode = c.$2; });
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Google Logo Widget
// ══════════════════════════════════════════════════════════
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r  = size.width / 2;

    // Draw circle background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Draw colored "G" segments using arcs
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.85);

    void drawArc(double startAngle, double sweepAngle, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.3
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.62),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    const pi = 3.14159265358979;
    // Blue (top-right to bottom-right)
    drawArc(-pi / 4, pi / 2 + pi / 6, const Color(0xFF4285F4));
    // Green (bottom-right to bottom-left)
    drawArc(pi / 3, pi / 2, const Color(0xFF34A853));
    // Yellow (bottom-left)
    drawArc(5 * pi / 6, pi / 3, const Color(0xFFFBBC05));
    // Red (top)
    drawArc(7 * pi / 6, 2 * pi / 3, const Color(0xFFEA4335));

    // Draw the horizontal bar of G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = r * 0.28
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.78, cy),
      barPaint,
    );

    // White center to create ring effect
    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.42, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ══════════════════════════════════════════════════════════

class _TabSwitcher extends StatelessWidget {
  final int selected;
  final List<String> labels;
  final ValueChanged<int> onTap;
  const _TabSwitcher({required this.selected, required this.labels, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: active ? kAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? kDark : kTextMute,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _VField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixWidget;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _VField({
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixWidget,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSub, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: kTextMain, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF3A4050), fontSize: 14),
            prefixIcon: prefixWidget ??
                (icon != null ? Icon(icon, color: kTextMute, size: 20) : null),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: kCard,
            border: _border(kBorder),
            enabledBorder: _border(kBorder),
            focusedBorder: _border(kAccent, width: 1.5),
            errorBorder: _border(Colors.redAccent),
            focusedErrorBorder: _border(Colors.redAccent, width: 1.5),
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.0}) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color, width: width));
}
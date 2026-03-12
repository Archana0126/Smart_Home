import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import 'login_screen.dart' show kBg, kCard, kBorder, kAccent, kTextMain, kTextSub, kTextMute, kDark;

// ══════════════════════════════════════════════════════════
//  OTP SCREEN
// ══════════════════════════════════════════════════════════
class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  late String _verificationId;
  int? _resendToken;

  final _pinController = TextEditingController();
  final _pinFocusNode  = FocusNode();

  OtpStatus _status  = OtpStatus.idle;
  String?   _errorText;

  static const int _timerMax = 30;
  int    _secondsLeft = _timerMax;
  Timer? _timer;

  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken    = widget.resendToken;

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0,  end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end:  8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin:  8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end:  0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _startTimer();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _timer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _timerMax);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        setState(() {});
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length < 6) return;
    setState(() { _status = OtpStatus.loading; _errorText = null; });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      setState(() => _status = OtpStatus.success);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      _pinController.clear();
      setState(() {
        _status    = OtpStatus.error;
        _errorText = e.code == 'invalid-verification-code'
            ? 'Invalid OTP. Please try again.'
            : (e.message ?? 'Verification failed');
      });
      _shakeCtrl.forward(from: 0);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() { _status = OtpStatus.idle; _errorText = null; });
    }
  }

  Future<void> _resendOtp() async {
    if (_secondsLeft > 0) return;
    setState(() => _status = OtpStatus.loading);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      },
      verificationFailed: (e) {
        setState(() { _status = OtpStatus.idle; _errorText = e.message; });
      },
      codeSent: (newId, resendToken) {
        setState(() {
          _verificationId = newId;
          _resendToken    = resendToken;
          _status         = OtpStatus.idle;
          _errorText      = null;
        });
        _startTimer();
        _pinController.clear();
        _pinFocusNode.requestFocus();
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  PinTheme _pinTheme(Color borderColor, {Color? fill, Color? textColor}) =>
      PinTheme(
        width: 52,
        height: 56,
        textStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textColor ?? kTextMain,
        ),
        decoration: BoxDecoration(
          color: fill ?? kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isLoading = _status == OtpStatus.loading;
    final isSuccess = _status == OtpStatus.success;
    final isError   = _status == OtpStatus.error;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kTextMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              const Text(
                'OTP Verification',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: kTextMain,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  text: 'We have sent you an OTP on ',
                  style: const TextStyle(fontSize: 14, color: kTextSub, height: 1.5),
                  children: [
                    TextSpan(
                      text: widget.phoneNumber,
                      style: const TextStyle(color: kTextMain, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── Pinput with shake on error ──
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(_shakeAnim.value, 0), child: child),
                child: Pinput(
                  length: 6,
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  autofocus: true,
                  // ✅ FIXED: Removed androidSmsAutofillMethod and
                  //    listenForMultipleSmsOnAndroid — both were removed in pinput v3+
                  hapticFeedbackType: HapticFeedbackType.lightImpact,
                  onCompleted: isLoading ? null : _verifyOtp,

                  defaultPinTheme: _pinTheme(kBorder),
                  focusedPinTheme: _pinTheme(kAccent,
                      fill: kAccent.withOpacity(0.08)),
                  submittedPinTheme: isError
                      ? _pinTheme(Colors.redAccent,
                          fill: Colors.redAccent.withOpacity(0.08),
                          textColor: Colors.redAccent)
                      : isSuccess
                          ? _pinTheme(kAccent,
                              fill: kAccent.withOpacity(0.12),
                              textColor: kAccent)
                          : _pinTheme(kBorder.withOpacity(0.6),
                              fill: kCard.withOpacity(0.6)),
                  cursor: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 9),
                        width: 22, height: 2,
                        decoration: BoxDecoration(
                          color: kAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              _StatusRow(status: _status, errorText: _errorText),
              const SizedBox(height: 32),

              // ── Resend timer / link ──
              _secondsLeft > 0
                  ? RichText(
                      text: TextSpan(
                        text: 'Resend OTP in ',
                        style: const TextStyle(fontSize: 13, color: kTextMute),
                        children: [
                          TextSpan(
                            text: '$_secondsLeft sec',
                            style: const TextStyle(
                                color: kTextSub, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : GestureDetector(
                      onTap: isLoading ? null : _resendOtp,
                      child: RichText(
                        text: const TextSpan(
                          text: "Didn't receive OTP? ",
                          style: TextStyle(fontSize: 13, color: kTextMute),
                          children: [
                            TextSpan(
                              text: 'Resend',
                              style: TextStyle(color: kAccent, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),

              const Spacer(),

              // ── Verify button ──
              SizedBox(
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: isLoading
                      ? Container(
                          key: const ValueKey('loading'),
                          height: 58,
                          decoration: BoxDecoration(
                            color: kAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: kAccent, strokeWidth: 2.5),
                          ),
                        )
                      : isSuccess
                          ? Container(
                              key: const ValueKey('success'),
                              height: 58,
                              decoration: BoxDecoration(
                                  color: kAccent,
                                  borderRadius: BorderRadius.circular(18)),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: kDark, size: 22),
                                  SizedBox(width: 8),
                                  Text('Verified!',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: kDark)),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              key: const ValueKey('verify'),
                              onPressed: () {
                                if (_pinController.text.length == 6) {
                                  _verifyOtp(_pinController.text);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kAccent,
                                foregroundColor: kDark,
                                minimumSize: const Size(double.infinity, 58),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                                elevation: 0,
                              ),
                              child: const Text('Verify OTP',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3)),
                            ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

enum OtpStatus { idle, loading, success, error }

class _StatusRow extends StatelessWidget {
  final OtpStatus status;
  final String?   errorText;
  const _StatusRow({required this.status, this.errorText});

  @override
  Widget build(BuildContext context) {
    if (status == OtpStatus.error && errorText != null) {
      return Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
        const SizedBox(width: 6),
        Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
      ]);
    }
    if (status == OtpStatus.success) {
      return const Row(children: [
        Icon(Icons.check_circle_outline_rounded, color: kAccent, size: 16),
        SizedBox(width: 6),
        Text('OTP verified successfully!',
            style: TextStyle(color: kAccent, fontSize: 13)),
      ]);
    }
    return const SizedBox.shrink();
  }
}
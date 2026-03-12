import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ─── Colors ───────────────────────────────────────────────
const _kBg      = Color(0xFF0A0C10);
const _kCard    = Color(0xFF111318);
const _kBorder  = Color(0xFF1E2530);
const _kAccent  = Color(0xFF3DE8C4);
const _kText    = Color(0xFFE8EAF0);
const _kSub     = Color(0xFF8090A8);
const _kMuted   = Color(0xFF5A6070);
const _kDark    = Color(0xFF071A16);
const _kError   = Color(0xFFFF5C5C);

const String _kDeviceIp = '192.168.10.1';

// ═══════════════════════════════════════════════════════════
//  WifiScanScreen
// ═══════════════════════════════════════════════════════════

class WifiScanScreen extends StatefulWidget {
  final String deviceName;
  const WifiScanScreen({super.key, required this.deviceName});
  @override
  State<WifiScanScreen> createState() => _WifiScanScreenState();
}

enum _ScanState { idle, scanning, timeout, found }

class _WifiScanScreenState extends State<WifiScanScreen> with TickerProviderStateMixin {
  _ScanState _state = _ScanState.idle;
  Timer? _scanTimer;
  int _elapsed = 0;
  Timer? _countTimer;
  List<WiFiAccessPoint> _results = [];
  String? _errorMessage;

  late final AnimationController _ring1;
  late final AnimationController _ring2;
  late final AnimationController _ring3;

  @override
  void initState() {
    super.initState();
    _ring1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _ring2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _ring3 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    Future.delayed(const Duration(milliseconds: 400), () { if (mounted) _ring2.forward(from: 0.3); });
    Future.delayed(const Duration(milliseconds: 800), () { if (mounted) _ring3.forward(from: 0.6); });
  }

  Future<void> _startScan() async {
    setState(() { _state = _ScanState.scanning; _elapsed = 0; _results = []; _errorMessage = null; });
    final locationStatus = await Permission.locationWhenInUse.request();
    if (!locationStatus.isGranted) {
      if (mounted) setState(() { _state = _ScanState.timeout; _errorMessage = 'Location permission denied.'; });
      return;
    }
    final can = await WiFiScan.instance.canStartScan(askPermissions: true);
    if (can != CanStartScan.yes) {
      if (mounted) setState(() { _state = _ScanState.timeout; _errorMessage = 'Cannot start scan: $can'; });
      return;
    }
    _countTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _elapsed++);
    });
    final started = await WiFiScan.instance.startScan();
    if (!started) {
      _countTimer?.cancel();
      if (mounted) setState(() { _state = _ScanState.timeout; _errorMessage = 'Failed to start WiFi scan.'; });
      return;
    }
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (t) async {
      if (!mounted) { t.cancel(); return; }
      final canGet = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
      if (canGet != CanGetScannedResults.yes) return;
      final accessPoints = await WiFiScan.instance.getScannedResults();
      if (accessPoints.isNotEmpty) {
        final filtered = accessPoints.where((ap) => ap.ssid.toUpperCase().startsWith('OVERA')).toList();
        if (filtered.isNotEmpty) {
          t.cancel(); _countTimer?.cancel();
          if (mounted) setState(() { _results = filtered; _state = _ScanState.found; });
          return;
        }
      }
      if (_elapsed >= 15) {
        t.cancel(); _countTimer?.cancel();
        if (mounted) setState(() { _state = _ScanState.timeout; _errorMessage = 'No device found nearby.\nMake sure your device is powered on.'; });
      }
    });
  }

  void _retry() { _scanTimer?.cancel(); _countTimer?.cancel(); _startScan(); }

  void _showWifiConnectSheet(WiFiAccessPoint ap) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent, isDismissible: false,
      builder: (_) => _WifiConnectSheet(ap: ap),
    );
  }

  @override
  void dispose() {
    _scanTimer?.cancel(); _countTimer?.cancel();
    _ring1.dispose(); _ring2.dispose(); _ring3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: _kText, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(
          _state == _ScanState.scanning ? 'Scanning Device' : _state == _ScanState.timeout ? 'Scan Failed' : _state == _ScanState.found ? 'Networks Found' : 'Connect Device',
          style: const TextStyle(color: _kText, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(child: Column(children: [
        Expanded(child: _state == _ScanState.found ? _buildResults() : Center(child: _state == _ScanState.timeout ? _buildTimeout() : _buildScanner())),
        _buildBottomBar(),
      ])),
    );
  }

  Widget _buildResults() {
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Row(children: [
        const Icon(Icons.router_rounded, color: _kAccent, size: 16), const SizedBox(width: 8),
        Text('${_results.length} device${_results.length == 1 ? '' : 's'} found', style: const TextStyle(fontSize: 13, color: _kSub, fontWeight: FontWeight.w500)),
      ])),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: _results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final ap = _results[i];
          final ssid = ap.ssid.isEmpty ? '(Hidden Network)' : ap.ssid;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
            child: Row(children: [
              Icon(ap.level > -60 ? Icons.wifi_rounded : ap.level > -75 ? Icons.wifi_2_bar_rounded : Icons.wifi_1_bar_rounded, color: _kAccent, size: 22),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ssid, style: const TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w600)),
                Text('Signal: ${ap.level} dBm', style: const TextStyle(color: _kMuted, fontSize: 11)),
              ])),
              ElevatedButton(
                onPressed: () => _showWifiConnectSheet(ap),
                style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: _kDark, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                child: const Text('Select', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]),
          );
        },
      )),
    ]);
  }

  Widget _buildScanner() {
    final isScanning = _state == _ScanState.scanning;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 240, height: 240, child: Stack(alignment: Alignment.center, children: [
        _AnimatedRing(controller: _ring3, size: 220, color: _kAccent, opacity: isScanning ? 0.08 : 0.04),
        _AnimatedRing(controller: _ring2, size: 160, color: _kAccent, opacity: isScanning ? 0.14 : 0.07),
        _AnimatedRing(controller: _ring1, size: 100, color: _kAccent, opacity: isScanning ? 0.22 : 0.1),
        AnimatedContainer(duration: const Duration(milliseconds: 400), width: 72, height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle, color: isScanning ? _kAccent.withOpacity(0.15) : _kCard, border: Border.all(color: isScanning ? _kAccent.withOpacity(0.5) : _kBorder, width: 1.5)),
          child: Icon(Icons.wifi_rounded, color: isScanning ? _kAccent : _kMuted, size: 32)),
      ])),
      const SizedBox(height: 32),
      Text(isScanning ? 'Searching for devices...' : 'Ready to scan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isScanning ? _kText : _kSub)),
      const SizedBox(height: 8),
      Text(isScanning ? 'Make sure ${widget.deviceName} is in pairing mode' : 'Tap "Start Scan" to find nearby devices', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _kMuted, height: 1.5)),
      if (isScanning) ...[
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(100), border: Border.all(color: _kBorder)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent, value: _elapsed / 15)),
            const SizedBox(width: 8),
            Text('${15 - _elapsed}s remaining', style: const TextStyle(fontSize: 12, color: _kSub, fontWeight: FontWeight.w500)),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildTimeout() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent.withOpacity(0.1), border: Border.all(color: Colors.redAccent.withOpacity(0.3))), child: const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 38)),
      const SizedBox(height: 28),
      const Text('No Device Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
      if (_errorMessage != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8), child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.redAccent, height: 1.5))),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text('We couldn\'t find any device nearby.\nMake sure it\'s in pairing mode and try again.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _kMuted, height: 1.6))),
      const SizedBox(height: 28),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 32), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Tips to fix this:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kSub)),
          SizedBox(height: 10),
          _TipRow(icon: Icons.power_settings_new_rounded, text: 'Reset the device and try again'),
          SizedBox(height: 8),
          _TipRow(icon: Icons.wifi_rounded, text: 'Make sure your phone\'s WiFi is on'),
          SizedBox(height: 8),
          _TipRow(icon: Icons.location_on_outlined, text: 'Enable Location Services on your phone'),
          SizedBox(height: 8),
          _TipRow(icon: Icons.straighten_rounded, text: 'Keep device within 1 meter'),
        ]),
      ),
    ]);
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _state == _ScanState.scanning ? null : _state == _ScanState.timeout || _state == _ScanState.found ? _retry : _startScan,
        style: ElevatedButton.styleFrom(
            backgroundColor: _state == _ScanState.timeout ? Colors.redAccent : _kAccent,
            disabledBackgroundColor: _kCard, foregroundColor: _kDark,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (_state == _ScanState.scanning) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _kMuted))
          else Icon(_state == _ScanState.timeout ? Icons.refresh_rounded : _state == _ScanState.found ? Icons.refresh_rounded : Icons.wifi_find_rounded, size: 18, color: _state == _ScanState.timeout ? _kText : _kDark),
          const SizedBox(width: 8),
          Text(_state == _ScanState.scanning ? 'Scanning...' : _state == _ScanState.timeout ? 'Try Again' : _state == _ScanState.found ? 'Scan Again' : 'Start Scan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _state == _ScanState.scanning ? _kMuted : _state == _ScanState.timeout ? _kText : _kDark)),
        ]),
      )),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  STEP 1 — _WifiConnectSheet
//  Connects phone to Overa_SP → pings ESP → opens ProvisionSheet
// ═══════════════════════════════════════════════════════════

enum _ConnectStep { form, connecting, verifying, success, failed }

class _WifiConnectSheet extends StatefulWidget {
  final WiFiAccessPoint ap;
  const _WifiConnectSheet({required this.ap});
  @override
  State<_WifiConnectSheet> createState() => _WifiConnectSheetState();
}

class _WifiConnectSheetState extends State<_WifiConnectSheet> with SingleTickerProviderStateMixin {
  final TextEditingController _pwCtrl = TextEditingController();
  bool _obscurePw = true;
  _ConnectStep _step = _ConnectStep.form;
  String? _errorMsg;
  String _statusMsg = '';

  late final AnimationController _successAnim;
  late final Animation<double> _scaleAnim;

  String get _ssid => widget.ap.ssid.isEmpty ? '(Hidden Network)' : widget.ap.ssid;

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = CurvedAnimation(parent: _successAnim, curve: Curves.elasticOut);
  }

  @override
  void dispose() { _pwCtrl.dispose(); _successAnim.dispose(); super.dispose(); }

  Future<void> _connect() async {
    final pw = _pwCtrl.text;
    if (pw.isEmpty) { setState(() => _errorMsg = 'Please enter the WiFi password.'); return; }

    setState(() { _step = _ConnectStep.connecting; _statusMsg = 'Connecting to "$_ssid"...'; _errorMsg = null; });
    debugPrint('>>> Connecting to $_ssid ...');

    try {
      final connected = await WiFiForIoTPlugin.connect(
        widget.ap.ssid, password: pw, security: NetworkSecurity.WPA, joinOnce: false, withInternet: false,
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      if (!connected) { setState(() { _step = _ConnectStep.failed; _errorMsg = 'Could not join "$_ssid".\nPassword may be incorrect.'; }); return; }

      debugPrint('>>> Joined AP $_ssid ✓');
      setState(() { _step = _ConnectStep.verifying; _statusMsg = 'Verifying device connection...'; });

      await Future.delayed(const Duration(seconds: 2));
      await WiFiForIoTPlugin.forceWifiUsage(true);
      await Future.delayed(const Duration(seconds: 3));

      bool reachable = false;
      try {
        reachable = await _pingDevice();
      } finally {
        await WiFiForIoTPlugin.forceWifiUsage(false);
      }

      if (!mounted) return;

      if (reachable) {
        setState(() => _step = _ConnectStep.success);
        _successAnim.forward();
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        Navigator.pop(context);
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        showModalBottomSheet(
          context: context, isScrollControlled: true,
          backgroundColor: Colors.transparent, isDismissible: false,
          builder: (_) => _ProvisionSheet(deviceSsid: _ssid),
        );
      } else {
        setState(() { _step = _ConnectStep.failed; _errorMsg = 'Phone joined "$_ssid" but the device at $_kDeviceIp is not responding.\nMake sure the device is powered on.'; });
      }

    } on TimeoutException {
      if (!mounted) return;
      setState(() { _step = _ConnectStep.failed; _errorMsg = 'Connection timed out. Move closer and try again.'; });
    } catch (e) {
      if (!mounted) return;
      String r = e.toString();
      if (r.contains('AUTHENTICATION_FAILURE') || r.contains('auth')) r = 'Incorrect password.';
      else if (r.contains('DHCP')) r = 'Could not get an IP address.';
      else if (r.contains('ASSOCIATION_REJECTION')) r = 'Device rejected the connection.';
      else r = 'Failed: $r';
      setState(() { _step = _ConnectStep.failed; _errorMsg = r; });
    }
  }

  Future<bool> _pingDevice() async {
    for (int i = 1; i <= 5; i++) {
      try {
        if (mounted) setState(() => _statusMsg = 'Verifying device... ($i/5)');
        debugPrint('>>> Ping $i → http://$_kDeviceIp/');
        final res = await http.get(Uri.parse('http://$_kDeviceIp/')).timeout(const Duration(seconds: 4));
        debugPrint('>>> Ping ${res.statusCode}');
        return true;
      } on TimeoutException { debugPrint('>>> Ping $i timed out');
      } catch (e) { debugPrint('>>> Ping $i error: $e'); }
      await Future.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottom),
      child: Container(
        decoration: const BoxDecoration(color: _kCard, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _DragHandle(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: switch (_step) {
                _ConnectStep.success    => _buildSuccess(),
                _ConnectStep.connecting => _buildSpinner('conn', _statusMsg, 'This may take a few seconds'),
                _ConnectStep.verifying  => _buildSpinner('ver', _statusMsg, 'Pinging device at $_kDeviceIp', icon: Icons.router_rounded),
                _ConnectStep.failed     => _buildFailed(),
                _ConnectStep.form       => _buildForm(),
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(key: const ValueKey('form'), crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: _kAccent.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
            child: Icon(widget.ap.level > -60 ? Icons.wifi_rounded : widget.ap.level > -75 ? Icons.wifi_2_bar_rounded : Icons.wifi_1_bar_rounded, color: _kAccent, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_ssid, style: const TextStyle(color: _kText, fontSize: 17, fontWeight: FontWeight.w800)),
          Text('Signal: ${widget.ap.level} dBm', style: const TextStyle(color: _kMuted, fontSize: 12)),
        ])),
      ]),
      const SizedBox(height: 24),
      const _FieldLabel(label: 'Device Password'),
      const SizedBox(height: 8),
      _PasswordField(controller: _pwCtrl, hint: 'Enter device WiFi password', obscure: _obscurePw, onToggle: () => setState(() => _obscurePw = !_obscurePw), onSubmit: (_) => _connect()),
      if (_errorMsg != null) ...[const SizedBox(height: 10), _ErrorRow(msg: _errorMsg!)],
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _connect,
        style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: _kDark, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
        child: const Text('Connect', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      )),
    ]);
  }

  Widget _buildSpinner(String key, String title, String subtitle, {IconData? icon}) {
    return Padding(key: ValueKey(key), padding: const EdgeInsets.symmetric(vertical: 40), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Stack(alignment: Alignment.center, children: [
        SizedBox(width: 64, height: 64, child: CircularProgressIndicator(strokeWidth: 3, color: _kAccent, backgroundColor: _kAccent.withOpacity(0.12))),
        if (icon != null) Icon(icon, color: _kAccent, size: 28),
      ]),
      const SizedBox(height: 20),
      Text(title, style: const TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text(subtitle, style: const TextStyle(color: _kSub, fontSize: 12)),
    ]));
  }

  Widget _buildSuccess() {
    return Padding(key: const ValueKey('success'), padding: const EdgeInsets.symmetric(vertical: 32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      ScaleTransition(scale: _scaleAnim, child: Container(width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _kAccent.withOpacity(0.12), border: Border.all(color: _kAccent.withOpacity(0.4), width: 1.5)),
          child: const Icon(Icons.check_rounded, color: _kAccent, size: 40))),
      const SizedBox(height: 20),
      const Text('Device Found!', style: TextStyle(color: _kText, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Opening WiFi setup...', style: TextStyle(color: _kSub, fontSize: 13)),
      const SizedBox(height: 20),
      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent)),
    ]));
  }

  Widget _buildFailed() {
    return Column(key: const ValueKey('failed'), crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: _kError.withOpacity(0.10), border: Border.all(color: _kError.withOpacity(0.35), width: 1.5)), child: const Icon(Icons.wifi_off_rounded, color: _kError, size: 36)),
      const SizedBox(height: 18),
      const Text('Connection Failed', style: TextStyle(color: _kText, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      if (_errorMsg != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(_errorMsg!, textAlign: TextAlign.center, style: const TextStyle(color: _kError, fontSize: 13, height: 1.6))),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => setState(() { _step = _ConnectStep.form; _errorMsg = null; }), style: OutlinedButton.styleFrom(foregroundColor: _kText, side: const BorderSide(color: _kBorder), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('Try Again', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(onPressed: _connect, style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: _kDark, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0), child: const Text('Retry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)))),
      ]),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
//  STEP 2 — _ProvisionSheet
//  User enters HOME WiFi name + password
//  1. forceWifiUsage(true)  → disconnects global WiFi routing
//                            → all HTTP goes through Overa_SP locally
//  2. Builds URL:  http://192.168.10.1/data?name={"Type":1,"SSID":"...","PWS":"..."}
//  3. ESP responds: {"Status":"Saved","MAC":"AABBCCDDEEFF"}
//  4. MAC stored in SharedPreferences + shown on screen
//  5. "Check Connection" button → opens Step 3 _ConnectionStatusSheet
// ═══════════════════════════════════════════════════════════

enum _ProvisionStep { form, sending, success, failed }

class _ProvisionSheet extends StatefulWidget {
  final String deviceSsid;
  const _ProvisionSheet({required this.deviceSsid});
  @override
  State<_ProvisionSheet> createState() => _ProvisionSheetState();
}

class _ProvisionSheetState extends State<_ProvisionSheet> with SingleTickerProviderStateMixin {
  final TextEditingController _ssidCtrl = TextEditingController();
  final TextEditingController _pwCtrl   = TextEditingController();
  bool _obscurePw = true;
  _ProvisionStep _step = _ProvisionStep.form;
  String? _errorMsg;
  String _deviceMac = '';

  late final AnimationController _successAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _successAnim, curve: Curves.elasticOut);
  }

  @override
  void dispose() { _ssidCtrl.dispose(); _pwCtrl.dispose(); _successAnim.dispose(); super.dispose(); }

  Future<void> _sendCredentials() async {
    final homeSsid = _ssidCtrl.text.trim();
    final homePw   = _pwCtrl.text;

    if (homeSsid.isEmpty) { setState(() => _errorMsg = 'Please enter your home WiFi name.'); return; }
    if (homePw.isEmpty)   { setState(() => _errorMsg = 'Please enter your home WiFi password.'); return; }

    setState(() { _step = _ProvisionStep.sending; _errorMsg = null; });

    // ── Build URL in exact required format ─────────────────
    // → http://192.168.10.1/data?name={"Type":1,"SSID":"MyWiFi","PWS":"pass123"}
    final payload = jsonEncode({'Type': 1, 'SSID': homeSsid, 'PWS': homePw});
    final url = Uri.parse('http://$_kDeviceIp/data').replace(queryParameters: {'name': payload});
    debugPrint('>>> Sending to ESP: $url');

    try {
      // ── Disconnect global WiFi → route all traffic through Overa_SP locally ──
      await WiFiForIoTPlugin.forceWifiUsage(true);

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      // ── Re-enable global WiFi routing after request ────────
      await WiFiForIoTPlugin.forceWifiUsage(false);

      debugPrint('>>> ESP response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final body   = jsonDecode(response.body) as Map<String, dynamic>;
        final status = body['Status'] ?? '';
        final mac    = (body['MAC'] ?? '').toString();

        if (status == 'Saved') {
          _deviceMac = mac;
          debugPrint('>>> Saved! MAC: $_deviceMac');

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('device_mac', _deviceMac);

          if (!mounted) return;
          setState(() => _step = _ProvisionStep.success);
          _successAnim.forward();
        } else {
          setState(() { _step = _ProvisionStep.failed; _errorMsg = 'Unexpected response from device: $status'; });
        }
      } else {
        setState(() { _step = _ProvisionStep.failed; _errorMsg = 'Device error (${response.statusCode}). Try again.'; });
      }

    } on TimeoutException {
      await WiFiForIoTPlugin.forceWifiUsage(false);
      if (!mounted) return;
      setState(() { _step = _ProvisionStep.failed; _errorMsg = 'Request timed out.\nStay connected to "${widget.deviceSsid}" and try again.'; });
    } catch (e) {
      await WiFiForIoTPlugin.forceWifiUsage(false);
      debugPrint('>>> Send error: $e');
      if (!mounted) return;
      setState(() { _step = _ProvisionStep.failed; _errorMsg = 'Could not reach device.\nMake sure you are still on "${widget.deviceSsid}".'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return PopScope(
      canPop: _step == _ProvisionStep.form || _step == _ProvisionStep.failed || _step == _ProvisionStep.success,
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 0, bottom),
        child: Container(
          decoration: const BoxDecoration(color: _kCard, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _DragHandle(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: switch (_step) {
                  _ProvisionStep.sending => _buildSending(),
                  _ProvisionStep.success => _buildSuccess(),
                  _ProvisionStep.failed  => _buildFailed(),
                  _ProvisionStep.form    => _buildForm(),
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(key: const ValueKey('prov_form'), crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: _kAccent.withOpacity(0.10), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.home_rounded, color: _kAccent, size: 24)),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Home WiFi Setup', style: TextStyle(color: _kText, fontSize: 17, fontWeight: FontWeight.w800)),
          SizedBox(height: 2),
          Text('Enter your home WiFi to provision device', style: TextStyle(color: _kMuted, fontSize: 12)),
        ])),
      ]),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _kAccent.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: _kAccent.withOpacity(0.2))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, color: _kAccent, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text('These credentials are sent locally to your device so it can connect to your home network.',
              style: TextStyle(fontSize: 12, color: _kAccent.withOpacity(0.85), height: 1.5))),
        ]),
      ),
      const _FieldLabel(label: 'Home WiFi Name (SSID)'),
      const SizedBox(height: 8),
      TextField(
        controller: _ssidCtrl,
        style: const TextStyle(color: _kText, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'e.g. MyHomeWiFi',
          hintStyle: const TextStyle(color: _kMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.wifi_rounded, color: _kSub, size: 18),
          filled: true, fillColor: _kBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kAccent, width: 1.5)),
        ),
      ),
      const SizedBox(height: 16),
      const _FieldLabel(label: 'Home WiFi Password'),
      const SizedBox(height: 8),
      _PasswordField(controller: _pwCtrl, hint: 'Enter home WiFi password', obscure: _obscurePw, onToggle: () => setState(() => _obscurePw = !_obscurePw), onSubmit: (_) => _sendCredentials()),
      if (_errorMsg != null) ...[const SizedBox(height: 10), _ErrorRow(msg: _errorMsg!)],
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _sendCredentials,
        style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: _kDark, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.send_rounded, size: 16),
          SizedBox(width: 8),
          Text('Send to Device', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      )),
    ]);
  }

  Widget _buildSending() {
    return Padding(key: const ValueKey('sending'), padding: const EdgeInsets.symmetric(vertical: 48), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Stack(alignment: Alignment.center, children: [
        SizedBox(width: 64, height: 64, child: CircularProgressIndicator(strokeWidth: 3, color: _kAccent, backgroundColor: _kAccent.withOpacity(0.12))),
        const Icon(Icons.send_rounded, color: _kAccent, size: 26),
      ]),
      const SizedBox(height: 20),
      const Text('Sending credentials to device...', style: TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      const SizedBox(height: 6),
      const Text('Device will restart automatically after saving', style: TextStyle(color: _kSub, fontSize: 12)),
    ]));
  }

  Widget _buildSuccess() {
    final formatted = _deviceMac.length == 12
        ? List.generate(6, (i) => _deviceMac.substring(i * 2, i * 2 + 2)).join(':').toUpperCase()
        : _deviceMac.toUpperCase();

    return Padding(key: const ValueKey('prov_success'), padding: const EdgeInsets.symmetric(vertical: 24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      ScaleTransition(scale: _scaleAnim, child: Container(width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _kAccent.withOpacity(0.12), border: Border.all(color: _kAccent.withOpacity(0.4), width: 1.5)),
          child: const Icon(Icons.check_rounded, color: _kAccent, size: 40))),
      const SizedBox(height: 20),
      const Text('Credentials Saved!', style: TextStyle(color: _kText, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Device received your WiFi credentials.\nNow checking if it connected successfully.',
          style: TextStyle(color: _kSub, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
      if (_deviceMac.isNotEmpty) ...[
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder)),
          child: Column(children: [
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.memory_rounded, color: _kAccent, size: 14),
              SizedBox(width: 6),
              Text('DEVICE MAC ADDRESS', style: TextStyle(fontSize: 10, color: _kSub, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ]),
            const SizedBox(height: 12),
            Text(formatted, style: const TextStyle(color: _kAccent, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2.5)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: formatted));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('MAC address copied!'),
                  backgroundColor: _kCard, behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: _kAccent.withOpacity(0.10), borderRadius: BorderRadius.circular(8), border: Border.all(color: _kAccent.withOpacity(0.25))),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.copy_rounded, size: 13, color: _kAccent),
                  SizedBox(width: 6),
                  Text('Copy MAC', style: TextStyle(fontSize: 12, color: _kAccent, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
      ],
      const SizedBox(height: 24),
      // ── Opens Step 3: polls ESP /status to confirm home WiFi connection ──
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () {
          final homeSsid = _ssidCtrl.text.trim();
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!context.mounted) return;
            showModalBottomSheet(
              context: context, isScrollControlled: true,
              backgroundColor: Colors.transparent, isDismissible: false,
              builder: (_) => _ConnectionStatusSheet(homeSsid: homeSsid, deviceMac: formatted),
            );
          });
        },
        style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: _kDark, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.wifi_find_rounded, size: 16),
          SizedBox(width: 8),
          Text('Check Connection', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      )),
    ]));
  }

  Widget _buildFailed() {
    return Column(key: const ValueKey('prov_failed'), crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: _kError.withOpacity(0.10), border: Border.all(color: _kError.withOpacity(0.35), width: 1.5)), child: const Icon(Icons.cloud_off_rounded, color: _kError, size: 36)),
      const SizedBox(height: 18),
      const Text('Send Failed', style: TextStyle(color: _kText, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      if (_errorMsg != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(_errorMsg!, textAlign: TextAlign.center, style: const TextStyle(color: _kError, fontSize: 13, height: 1.6))),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => setState(() { _step = _ProvisionStep.form; _errorMsg = null; }), style: OutlinedButton.styleFrom(foregroundColor: _kText, side: const BorderSide(color: _kBorder), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('Edit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(onPressed: _sendCredentials, style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: _kDark, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0), child: const Text('Retry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)))),
      ]),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
//  STEP 3 — _ConnectionStatusSheet
//  Polls http://192.168.10.1/status every 3s (up to 30s total)
//
//  ESP8266 must expose GET /status returning JSON:
//    {"Status": 1}  → still connecting (keep polling)
//    {"Status": 2}  → successfully connected to home WiFi ✓
//    {"Status": 3}  → failed to connect to home WiFi ✗
//
//  On Status 2 → "Device Online!" screen with MAC + "All Done"
//  On Status 3 or timeout → "Connection Failed" with Retry button
// ═══════════════════════════════════════════════════════════

enum _WiFiConnStatus { polling, connected, failed }

class _ConnectionStatusSheet extends StatefulWidget {
  final String homeSsid;
  final String deviceMac;
  const _ConnectionStatusSheet({required this.homeSsid, required this.deviceMac});
  @override
  State<_ConnectionStatusSheet> createState() => _ConnectionStatusSheetState();
}

class _ConnectionStatusSheetState extends State<_ConnectionStatusSheet>
    with SingleTickerProviderStateMixin {
  _WiFiConnStatus _status = _WiFiConnStatus.polling;
  Timer? _pollTimer;
  int _attempts = 0;
  final int _maxAttempts = 10; // 3s × 10 = 30s total

  late final AnimationController _successAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim   = CurvedAnimation(parent: _successAnim, curve: Curves.elasticOut);
    // Wait 5s for ESP to restart after saving credentials, then start polling
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
    });
  }

  void _resetAndRetry() {
    _pollTimer?.cancel();
    setState(() { _status = _WiFiConnStatus.polling; _attempts = 0; });
    _successAnim.reset();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
    });
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    _attempts++;
    debugPrint('>>> Polling /status attempt $_attempts/$_maxAttempts');

    try {
      // Force traffic through Overa_SP to reach ESP at 192.168.10.1
      await WiFiForIoTPlugin.forceWifiUsage(true);
      final res = await http
          .get(Uri.parse('http://$_kDeviceIp/status'))
          .timeout(const Duration(seconds: 4));
      await WiFiForIoTPlugin.forceWifiUsage(false);

      if (!mounted) return;
      final body       = jsonDecode(res.body) as Map<String, dynamic>;
      final statusCode = body['Status'] as int;
      debugPrint('>>> /status = $statusCode');

      if (statusCode == 2) {
        _pollTimer?.cancel();
        setState(() => _status = _WiFiConnStatus.connected);
        _successAnim.forward();
        return;
      } else if (statusCode == 3) {
        _pollTimer?.cancel();
        setState(() => _status = _WiFiConnStatus.failed);
        return;
      }
      // statusCode == 1 → still connecting, keep polling
    } catch (e) {
      await WiFiForIoTPlugin.forceWifiUsage(false);
      debugPrint('>>> Poll error: $e');
    }

    if (_attempts >= _maxAttempts) {
      _pollTimer?.cancel();
      if (mounted) setState(() => _status = _WiFiConnStatus.failed);
    } else {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _successAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _status != _WiFiConnStatus.polling,
      child: Container(
        decoration: const BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _DragHandle(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: switch (_status) {
              _WiFiConnStatus.polling   => _buildPolling(),
              _WiFiConnStatus.connected => _buildConnected(),
              _WiFiConnStatus.failed    => _buildFailed(),
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildPolling() {
    return Padding(
      key: const ValueKey('polling'),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 72, height: 72,
            child: CircularProgressIndicator(strokeWidth: 3, color: _kAccent, backgroundColor: _kAccent.withOpacity(0.12))),
          const Icon(Icons.router_rounded, color: _kAccent, size: 30),
        ]),
        const SizedBox(height: 24),
        const Text('Connecting to Home WiFi',
            style: TextStyle(color: _kText, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Device is joining "${widget.homeSsid}"...',
          style: const TextStyle(color: _kSub, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(100), border: Border.all(color: _kBorder)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 12, height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent, value: _attempts / _maxAttempts)),
            const SizedBox(width: 8),
            Text('Checking... ($_attempts/$_maxAttempts)',
                style: const TextStyle(fontSize: 12, color: _kSub, fontWeight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(height: 12),
        const Text('This may take up to 30 seconds',
            style: TextStyle(fontSize: 11, color: _kMuted)),
      ]),
    );
  }

  Widget _buildConnected() {
    return Padding(
      key: const ValueKey('connected'),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ScaleTransition(
          scale: _scaleAnim,
          child: Container(width: 88, height: 88,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _kAccent.withOpacity(0.12), border: Border.all(color: _kAccent.withOpacity(0.4), width: 1.5)),
            child: const Icon(Icons.wifi_rounded, color: _kAccent, size: 40)),
        ),
        const SizedBox(height: 20),
        const Text('Device Online!',
            style: TextStyle(color: _kText, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Your device successfully joined\n"${widget.homeSsid}"',
          style: const TextStyle(color: _kSub, fontSize: 13, height: 1.5),
          textAlign: TextAlign.center,
        ),
        if (widget.deviceMac.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.memory_rounded, color: _kAccent, size: 13),
              const SizedBox(width: 8),
              Text(widget.deviceMac,
                  style: const TextStyle(color: _kAccent, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ]),
          ),
        ],
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: _kDark, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
          child: const Text('All Done', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        )),
      ]),
    );
  }

  Widget _buildFailed() {
    return Column(
      key: const ValueKey('status_failed'),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(width: 88, height: 88,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _kError.withOpacity(0.10), border: Border.all(color: _kError.withOpacity(0.35), width: 1.5)),
          child: const Icon(Icons.wifi_off_rounded, color: _kError, size: 40)),
        const SizedBox(height: 20),
        const Text('Connection Failed',
            style: TextStyle(color: _kText, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(
          'Device could not join\n"${widget.homeSsid}".\nCheck the WiFi name & password.',
          style: const TextStyle(color: _kError, fontSize: 13, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('Check the following:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kSub)),
            SizedBox(height: 8),
            _TipRow(icon: Icons.lock_outline_rounded, text: 'WiFi password is correct'),
            SizedBox(height: 6),
            _TipRow(icon: Icons.wifi_rounded, text: 'Home WiFi name (SSID) is correct'),
            SizedBox(height: 6),
            _TipRow(icon: Icons.router_rounded, text: 'Home router is powered on'),
          ]),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(foregroundColor: _kText, side: const BorderSide(color: _kBorder), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: _resetAndRetry,
            style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: _kDark, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            child: const Text('Retry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          )),
        ]),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Shared Widgets
// ═══════════════════════════════════════════════════════════

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2))));
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String> onSubmit;
  const _PasswordField({required this.controller, required this.hint, required this.obscure, required this.onToggle, required this.onSubmit});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, obscureText: obscure,
      style: const TextStyle(color: _kText, fontSize: 14),
      onSubmitted: onSubmit,
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: _kMuted, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: _kSub, size: 18),
        suffixIcon: GestureDetector(onTap: onToggle, child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _kSub, size: 18)),
        filled: true, fillColor: _kBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kAccent, width: 1.5)),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String msg;
  const _ErrorRow({required this.msg});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Padding(padding: EdgeInsets.only(top: 1), child: Icon(Icons.error_outline_rounded, color: _kError, size: 14)),
    const SizedBox(width: 6),
    Expanded(child: Text(msg, style: const TextStyle(color: _kError, fontSize: 12, height: 1.4))),
  ]);
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label, style: const TextStyle(color: _kSub, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3));
}

class _AnimatedRing extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Color color;
  final double opacity;
  const _AnimatedRing({required this.controller, required this.size, required this.color, required this.opacity});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: controller, builder: (_, __) {
      final scale = 0.85 + 0.15 * controller.value;
      final fade  = (1.0 - controller.value).clamp(0.0, 1.0);
      return Transform.scale(scale: scale, child: Opacity(opacity: opacity * fade,
          child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.5)))));
    });
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: _kAccent), const SizedBox(width: 8),
    Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: _kSub))),
  ]);
}
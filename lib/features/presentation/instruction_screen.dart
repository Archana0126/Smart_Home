import 'package:flutter/material.dart';
import 'package:smart_home_project/features/presentation/scanning_screen.dart';

// ─── Colors ──────────────────────────────────────────────
const _kBg = Color(0xFF0A0C10);
const _kCard = Color(0xFF111318);
const _kBorder = Color(0xFF1E2530);
const _kAccent = Color(0xFF3DE8C4);
const _kText = Color(0xFFE8EAF0);
const _kSub = Color(0xFF8090A8);
const _kMuted = Color(0xFF5A6070);
const _kDark = Color(0xFF071A16);

// ─── Device Setup Config ──────────────────────────────────
class DeviceSetupConfig {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String resetTitle;
  final String resetNote;
  final List<String> steps;

  const DeviceSetupConfig({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.resetTitle,
    required this.resetNote,
    required this.steps,
  });
}

// ─── All Device Configs ───────────────────────────────────
const Map<String, DeviceSetupConfig> kDeviceConfigs = {
  'Light': DeviceSetupConfig(
    name: 'Light',
    subtitle: 'Smart Bulb',
    icon: Icons.lightbulb_outline_rounded,
    color: Color(0xFFF4C97A),
    resetTitle: 'Reset the bulb',
    resetNote: 'If the light is blinking fast, skip the reset step.',
    steps: [
      'Turn the bulb on and off 5 times rapidly to reset it.',
      'The bulb will flash, indicating it\'s ready for pairing.',
    ],
  ),
  'AC': DeviceSetupConfig(
    name: 'Air Conditioner',
    subtitle: 'Climate Control',
    icon: Icons.ac_unit_rounded,
    color: Color(0xFF4F8EF7),
    resetTitle: 'Prepare the AC',
    resetNote: 'Ensure the AC is powered on before starting.',
    steps: [
      'Press and hold the Reset button on the AC unit for 5 seconds.',
      'The indicator light will blink, showing it\'s ready to connect.',
    ],
  ),
  'Television': DeviceSetupConfig(
    name: 'Television',
    subtitle: 'Smart TV',
    icon: Icons.tv_rounded,
    color: Color(0xFFB07EFF),
    resetTitle: 'Prepare your TV',
    resetNote: 'Make sure your TV is connected to power.',
    steps: [
      'Go to Settings → Network → Smart Home on your TV.',
      'Enable pairing mode and wait for the TV to be discoverable.',
    ],
  ),
  'Fan': DeviceSetupConfig(
    name: 'Fan',
    subtitle: 'Ceiling / Table',
    icon: Icons.toys_outlined,
    color: Color(0xFF3DE8C4),
    resetTitle: 'Reset the fan',
    resetNote: 'If the fan is already blinking, skip the reset step.',
    steps: [
      'Turn the fan off, then press the reset button on the regulator for 5 seconds.',
      'The fan will beep or blink, indicating it\'s ready for pairing.',
    ],
  ),
  'Door Lock': DeviceSetupConfig(
    name: 'Door Lock',
    subtitle: 'Smart Lock',
    icon: Icons.lock_outline_rounded,
    color: Color(0xFFFF8A65),
    resetTitle: 'Reset the lock',
    resetNote: 'Ensure the lock has fresh batteries installed.',
    steps: [
      'Press and hold the reset button inside the battery compartment for 5 seconds.',
      'The lock will beep twice, indicating it\'s ready to pair.',
    ],
  ),
  'Camera': DeviceSetupConfig(
    name: 'Security Camera',
    subtitle: 'Camera',
    icon: Icons.videocam_outlined,
    color: Color(0xFFFF6B6B),
    resetTitle: 'Reset the camera',
    resetNote: 'If the LED is blinking red-blue, skip the reset step.',
    steps: [
      'Press and hold the reset button on the camera for 5 seconds.',
      'The LED will blink red and blue, indicating it\'s ready for pairing.',
    ],
  ),
  'Thermostat': DeviceSetupConfig(
    name: 'Thermostat',
    subtitle: 'Temperature',
    icon: Icons.thermostat_rounded,
    color: Color(0xFFF4C97A),
    resetTitle: 'Reset the thermostat',
    resetNote: 'Ensure the thermostat is mounted and powered on.',
    steps: [
      'Press and hold the Menu button for 5 seconds until the display flashes.',
      'Select "Reset" and confirm. The device is now ready to pair.',
    ],
  ),
  'Speaker': DeviceSetupConfig(
    name: 'Speaker',
    subtitle: 'Smart Speaker',
    icon: Icons.speaker_rounded,
    color: Color(0xFF4F8EF7),
    resetTitle: 'Reset the speaker',
    resetNote: 'If the ring is already spinning, skip the reset step.',
    steps: [
      'Press and hold the mute button for 10 seconds until the light ring turns orange.',
      'The light ring will spin blue, indicating the speaker is ready to pair.',
    ],
  ),
  'Microwave': DeviceSetupConfig(
    name: 'Microwave',
    subtitle: 'Smart Kitchen',
    icon: Icons.microwave_outlined,
    color: Color(0xFFFF8A65),
    resetTitle: 'Prepare the microwave',
    resetNote: 'Ensure the microwave is plugged in and powered on.',
    steps: [
      'Press and hold the Smart button on the control panel for 3 seconds.',
      'The display will show "PAIR", indicating it\'s ready to connect.',
    ],
  ),
  'Smart Plug': DeviceSetupConfig(
    name: 'Smart Plug',
    subtitle: 'Power Control',
    icon: Icons.power_outlined,
    color: Color(0xFF3DE8C4),
    resetTitle: 'Reset the device',
    resetNote: 'If the light is blinking fast, skip the reset step.',
    steps: [
      'Plug the switch to the socket and press the power button for 5 seconds to reset the device.',
      'The light will blink, indicating it\'s ready for pairing.',
    ],
  ),
};

// ─── Device Setup Screen ──────────────────────────────────
class DeviceSetupScreen extends StatelessWidget {
  final String deviceName;

  const DeviceSetupScreen({super.key, required this.deviceName});

  @override
  Widget build(BuildContext context) {
    final config = kDeviceConfigs[deviceName] ?? kDeviceConfigs['Smart Plug']!;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: _kText,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          config.name,
          style: const TextStyle(
            color: _kText,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Title ──
                    Text(
                      config.resetTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _kText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      config.resetNote,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kSub,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Device Illustration ──
                    Center(
                      child: Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(
                          color: const Color(0xFF14171F),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: config.color.withOpacity(0.2),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: config.color.withOpacity(0.15),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            // Outer ring
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: config.color.withOpacity(0.06),
                                border: Border.all(
                                  color: config.color.withOpacity(0.15),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            // Inner circle
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: config.color.withOpacity(0.1),
                                border: Border.all(
                                  color: config.color.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                config.icon,
                                color: config.color,
                                size: 42,
                              ),
                            ),
                            // Device name tag
                            Positioned(
                              bottom: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _kCard,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: _kBorder),
                                ),
                                child: Text(
                                  config.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: config.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Steps ──
                    ...List.generate(config.steps.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step number
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: config.color.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: config.color.withOpacity(0.3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: config.color,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Step text
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: _HighlightedText(
                                  text: config.steps[i],
                                  accentColor: config.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Continue Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WifiScanScreen(deviceName: config.name),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: _kDark,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Highlighted text (bolds text between ** **) ─────────
class _HighlightedText extends StatelessWidget {
  final String text;
  final Color accentColor;

  const _HighlightedText({required this.text, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final parts = text.split(RegExp(r'\*\*'));
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: i.isOdd ? accentColor : _kSub,
            fontWeight: i.isOdd ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      );
    }
    return RichText(text: TextSpan(children: spans));
  }
}

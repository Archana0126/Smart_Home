import 'package:flutter/material.dart';
import 'package:smart_home_project/features/presentation/instruction_screen.dart';

const _kBg     = Color(0xFF0A0C10);
const _kCard   = Color(0xFF111318);
const _kBorder = Color(0xFF1E2530);
const _kAccent = Color(0xFF3DE8C4);
const _kText   = Color(0xFFE8EAF0);
const _kSub    = Color(0xFF8090A8);
const _kMuted  = Color(0xFF5A6070);
const _kDark   = Color(0xFF071A16);

class _DeviceType {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _DeviceType({required this.name, required this.subtitle, required this.icon, required this.color});
}

class ChooseDeviceScreen extends StatefulWidget {
  const ChooseDeviceScreen({super.key});
  @override
  State<ChooseDeviceScreen> createState() => _ChooseDeviceScreenState();
}

class _ChooseDeviceScreenState extends State<ChooseDeviceScreen> {
  int? _selectedIndex;

  final List<_DeviceType> _devices = const [
    _DeviceType(name: 'Light',      subtitle: 'Smart Bulb',     icon: Icons.lightbulb_outline_rounded, color: Color(0xFFF4C97A)),
    _DeviceType(name: 'AC',         subtitle: 'Climate Control', icon: Icons.ac_unit_rounded,            color: Color(0xFF4F8EF7)),
    _DeviceType(name: 'Television', subtitle: 'Smart TV',        icon: Icons.tv_rounded,                 color: Color(0xFFB07EFF)),
    _DeviceType(name: 'Fan',        subtitle: 'Ceiling / Table', icon: Icons.toys_outlined,              color: Color(0xFF3DE8C4)),
    _DeviceType(name: 'Door Lock',  subtitle: 'Smart Lock',      icon: Icons.lock_outline_rounded,       color: Color(0xFFFF8A65)),
    _DeviceType(name: 'Camera',     subtitle: 'Security',        icon: Icons.videocam_outlined,          color: Color(0xFFFF6B6B)),
    _DeviceType(name: 'Thermostat', subtitle: 'Temperature',     icon: Icons.thermostat_rounded,         color: Color(0xFFF4C97A)),
    _DeviceType(name: 'Speaker',    subtitle: 'Smart Speaker',   icon: Icons.speaker_rounded,            color: Color(0xFF4F8EF7)),
    _DeviceType(name: 'Microwave',  subtitle: 'Smart Kitchen',   icon: Icons.microwave_outlined,         color: Color(0xFFFF8A65)),
    _DeviceType(name: 'Smart Plug', subtitle: 'Power Control',   icon: Icons.power_outlined,             color: Color(0xFF3DE8C4)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _kText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Choose Device',
            style: TextStyle(color: _kText, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('What would you\nlike to add?',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800,
                          height: 1.3, color: _kText, letterSpacing: -0.3)),
                  SizedBox(height: 6),
                  Text('Select a device type to get started.',
                      style: TextStyle(fontSize: 13, color: _kMuted)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Grid — uses LayoutBuilder to calculate ratio ──
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const crossAxisCount = 3;
                  const crossAxisSpacing = 12.0;
                  const horizontalPadding = 32.0; // 16 each side
                  final cellWidth = (constraints.maxWidth - horizontalPadding -
                      (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;

                  // Fixed cell content height:
                  // vertical padding 10+10 + icon 46 + gap 7 + name 14 + gap 2 + subtitle 12 + gap 5 + check 18 = 124
                  const cellHeight = 128.0;
                  final ratio = cellWidth / cellHeight;

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: crossAxisSpacing,
                      childAspectRatio: ratio,
                    ),
                    itemCount: _devices.length,
                    itemBuilder: (context, i) {
                      final device = _devices[i];
                      final selected = _selectedIndex == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            color: selected ? device.color.withOpacity(0.12) : _kCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? device.color.withOpacity(0.6) : _kBorder,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ── Icon ──
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? device.color.withOpacity(0.2)
                                        : device.color.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                      color: selected
                                          ? device.color.withOpacity(0.5)
                                          : device.color.withOpacity(0.15),
                                    ),
                                  ),
                                  child: Icon(device.icon, color: device.color, size: 22),
                                ),
                                const SizedBox(height: 7),
                                // ── Name ──
                                Text(
                                  device.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: selected ? _kText : _kSub,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // ── Subtitle ──
                                Text(
                                  device.subtitle,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: selected ? device.color.withOpacity(0.8) : _kMuted,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                // ── Checkmark — always same height slot ──
                                SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: selected
                                      ? Container(
                                          decoration: BoxDecoration(
                                            color: device.color,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check_rounded, color: _kDark, size: 12),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ── Bottom CTA ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedIndex != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeviceSetupScreen(
                                deviceName: _devices[_selectedIndex!].name,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    disabledBackgroundColor: _kCard,
                    foregroundColor: _kDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedIndex != null
                        ? 'Add ${_devices[_selectedIndex!].name}'
                        : 'Select a Device',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _selectedIndex != null ? _kDark : _kMuted,
                    ),
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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../core/platform/android_system.dart';
import '../../core/storage/preferences_service.dart';
import '../../domain/entities/vpn_connection_state.dart';
import '../../domain/repositories/connectivity_repository.dart';
import '../../presentation/controllers/vpn_controller.dart';
import '../activity/activity_view.dart';
import '../common/motion.dart';
import '../servers/servers_view.dart';
import '../settings/settings_view.dart';
import 'home_view.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late final AnimationController _tabCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final CurvedAnimation _slideCurve;
  final List<ValueNotifier<int>> _replayTriggers = List.generate(
    4,
    (_) => ValueNotifier<int>(0),
  );
  int _direction = 1;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _networkWasLost = false;
  bool _shouldReconnect = false;
  bool _isRecoveringConnection = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(parent: _tabCtrl, curve: Curves.easeInOutCubic);
    _scaleAnim = Tween<double>(
      begin: 0.985,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _tabCtrl, curve: Curves.easeOutCubic));
    _slideCurve = CurvedAnimation(parent: _tabCtrl, curve: Curves.easeOutCubic);
    _connectivitySubscription = context
        .read<ConnectivityRepository>()
        .onConnectivityChanged
        .listen(_handleConnectivityChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_autoConnectIfEnabled());
    });
  }

  Future<void> _autoConnectIfEnabled() async {
    if (!mounted) return;
    final prefs = context.read<PreferencesService>();
    final vpn = context.read<VpnController>();
    if (!prefs.autoConnect ||
        vpn.connectionState != VpnConnectionState.disconnected) {
      return;
    }
    await vpn.loadServers();
    if (mounted && vpn.connectionState == VpnConnectionState.disconnected) {
      await vpn.connectToFastestServer();
    }
  }

  void _handleConnectivityChange(bool isOnline) {
    final vpn = context.read<VpnController>();
    if (!isOnline) {
      _networkWasLost = true;
      _shouldReconnect =
          vpn.connectionState == VpnConnectionState.connected ||
          vpn.connectionState == VpnConnectionState.connecting ||
          vpn.connectionState == VpnConnectionState.checking ||
          vpn.connectionState == VpnConnectionState.error;
      return;
    }
    if (!_networkWasLost) return;
    _networkWasLost = false;
    if (_shouldReconnect &&
        context.read<PreferencesService>().reconnectOnNetworkChange) {
      unawaited(_recoverConnection());
    }
    _shouldReconnect = false;
  }

  Future<void> _recoverConnection() async {
    if (!mounted || _isRecoveringConnection) return;
    _isRecoveringConnection = true;
    try {
      final vpn = context.read<VpnController>();
      if (vpn.connectionState == VpnConnectionState.connected) {
        await vpn.disconnect();
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      if (mounted && vpn.connectionState != VpnConnectionState.connecting) {
        await vpn.connect();
      }
    } finally {
      _isRecoveringConnection = false;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _slideCurve.dispose();
    _tabCtrl.dispose();
    for (final trigger in _replayTriggers) {
      trigger.dispose();
    }
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      _direction = index > _currentIndex ? 1 : -1;
      _currentIndex = index;
    });
    _replayTriggers[index].value++;
    if (Motion.isReduced(context)) {
      _tabCtrl.value = 1.0;
    } else {
      _tabCtrl.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeView(onNavigateToServers: () => _onTabSelected(1)),
      ServersView(onServerConnected: () => _onTabSelected(0)),
      const ActivityView(),
      const SettingsView(),
    ];

    return PopScope(
      // Back never closes the app: it returns to the Home tab, then sends the
      // app to the background (like the Home button) so it reopens instantly
      // on the live connection instead of restarting from the splash screen.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          _onTabSelected(0);
        } else if (!await AndroidSystem.moveToBackground()) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.04 * _direction, 0),
              end: Offset.zero,
            ).animate(_slideCurve),
            child: ScaleTransition(
              scale: _scaleAnim,
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  for (int i = 0; i < pages.length; i++)
                    // Hidden tabs stay alive (state and scroll position kept)
                    // but their animations pause instead of ticking unseen.
                    TickerMode(
                      enabled: i == _currentIndex,
                      child: EntranceReplay(
                        trigger: _replayTriggers[i],
                        child: pages[i],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildCyberNavigationBar(),
      ),
    );
  }

  Widget _buildCyberNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground, // #121212
        border: const Border(
          top: BorderSide(
            color: AppColors.borderDivider, // #2D2D2D
            width: 1.0,
          ),
        ),
        boxShadow: Motion.shadows(context, [
          BoxShadow(color: Colors.black, blurRadius: 16, offset: Offset(0, -4)),
        ]),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Stack(
            children: [
              Positioned.fill(child: _buildSlidingIndicator()),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.shield_outlined,
                    selectedIcon: Icons.shield_rounded,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.dns_outlined,
                    selectedIcon: Icons.dns_rounded,
                    label: 'Servers',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.history_rounded,
                    selectedIcon: Icons.history_rounded,
                    label: 'Activity',
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings_rounded,
                    label: 'Settings',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pill that glides between tabs, with a glowing top accent line.
  Widget _buildSlidingIndicator() {
    return AnimatedAlign(
      alignment: Alignment(-1.0 + 2.0 * _currentIndex / 3, 0),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      child: FractionallySizedBox(
        widthFactor: 1 / 4,
        heightFactor: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDivider, width: 1.0),
          ),
          alignment: Alignment.topCenter,
          child: Container(
            width: 18,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.primaryText,
              borderRadius: BorderRadius.circular(2),
              boxShadow: Motion.shadows(context, [
                BoxShadow(
                  color: AppColors.primaryText.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabSelected(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: Tween<double>(begin: -0.08, end: 0).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    key: ValueKey(isSelected),
                    size: 21,
                    color: isSelected
                        ? AppColors.primaryText
                        : AppColors.mutedText,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryText
                      : AppColors.mutedText,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: isSelected ? 0.4 : 0.2,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

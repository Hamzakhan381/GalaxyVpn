import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/platform/android_system.dart';
import '../../core/platform/haptics.dart';
import '../../domain/entities/vpn_connection_state.dart';
import '../../domain/entities/vpn_live_metrics.dart';
import '../../presentation/controllers/vpn_controller.dart';
import '../common/connection_orb.dart';
import '../common/connection_status_badge.dart';
import '../common/country_badge.dart';
import '../common/cyber_background.dart';
import '../common/fastest_server_card.dart';
import '../common/ip_rotation_card.dart';
import '../common/motion.dart';
import '../common/secondary_button.dart';
import '../servers/server_details_sheet.dart';

/// Premium Obsidian & Pure White Cybersecurity VPN Home Screen.
class HomeView extends StatefulWidget {
  final VoidCallback onNavigateToServers;

  const HomeView({super.key, required this.onNavigateToServers});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();

  /// Horizontal shake for the error banner when a connection fails.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  late final VpnController _vpnRepo;
  late VpnConnectionState _lastState;

  @override
  void initState() {
    super.initState();
    _vpnRepo = context.read<VpnController>();
    _lastState = _vpnRepo.connectionState;
    _vpnRepo.addListener(_onVpnChanged);
  }

  void _onVpnChanged() {
    final state = _vpnRepo.connectionState;
    if (state == _lastState) return;
    _lastState = state;
    if (!mounted) return;

    if (state == VpnConnectionState.connected) {
      // Automatic IP changes reconnect every few minutes; only buzz when the
      // user started the connection.
      if (!_vpnRepo.connectedByRotation) Haptics.success();
    } else if (state == VpnConnectionState.error) {
      Haptics.error();
      if (!Motion.isReduced(context)) _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _vpnRepo.removeListener(_onVpnChanged);
    _scroll.dispose();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    Haptics.click();
    await _vpnRepo.detectFastestServer(forceProbe: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnController>(
      builder: (context, vpnRepo, _) {
        final rawState = vpnRepo.connectionState;
        // While IP rotation swaps relays the tunnel is briefly down: show it
        // as connecting to the next relay rather than as unprotected.
        final state =
            vpnRepo.isRotatingIp &&
                rawState != VpnConnectionState.connected &&
                rawState != VpnConnectionState.error
            ? VpnConnectionState.connecting
            : rawState;
        final selectedServer = vpnRepo.selectedServer;
        final isConnected = state == VpnConnectionState.connected;
        final isConnecting =
            state == VpnConnectionState.connecting ||
            state == VpnConnectionState.checking;
        final isDisconnecting = state == VpnConnectionState.disconnecting;
        final isError = state == VpnConnectionState.error;

        final themeAccent = isConnected
            ? AppColors.connectedStatus
            : isConnecting
            ? AppColors.primaryText
            : isError
            ? AppColors.errorStatus
            : AppColors.primaryText;

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(context, state),
          body: CyberBackground(
            glowAccentColor: themeAccent,
            vpnState: state,
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primaryText,
                backgroundColor: AppColors.elevatedSurface,
                child: SingleChildScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),

                      // ── Status badge ────────────────────────────────────────
                      AnimatedFadeSlide(
                        child: RepaintBoundary(
                          child: ConnectionStatusBadge(state: state),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Headline text (animated switch) ─────────────────────
                      AnimatedFadeSlide(
                        delayMs: Motion.staggerStepMs,
                        child: _AnimatedStatusText(
                          isConnected: isConnected,
                          isConnecting: isConnecting,
                          isDisconnecting: isDisconnecting,
                          isError: isError,
                          countryName: selectedServer?.country,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Central animated connect/disconnect button ───────────
                      AnimatedFadeSlide(
                        delayMs: Motion.staggerStepMs * 2,
                        duration: Motion.slow,
                        offset: const Offset(0, 0.04),
                        beginScale: 0.82,
                        // Own layer: the orb and its star field animate on
                        // their own without repainting the rest of Home.
                        child: _OrbStage(
                          scroll: _scroll,
                          child: RepaintBoundary(
                            child: ConnectionOrb(
                              state: state,
                              connectingCountry: selectedServer?.country,
                              onTap: () {
                                Haptics.heavy();
                                if (isConnected || isConnecting) {
                                  vpnRepo.disconnect();
                                } else if (!isDisconnecting) {
                                  // So the connection notification (with its
                                  // Disconnect action) can show on Android 13+.
                                  AndroidSystem.requestNotificationPermission();
                                  vpnRepo.connect();
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Fastest Server Auto-Detect & Suggestion Card ─────────
                      // Folds away while connected: the server card below
                      // already names the active relay, so the live stats
                      // move up into view instead of sitting below the fold.
                      AnimatedSize(
                        duration: Motion.medium,
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: isConnected || vpnRepo.isRotatingIp
                            ? const SizedBox(width: double.infinity)
                            : AnimatedFadeSlide(
                                delayMs: Motion.staggerStepMs * 3,
                                child: RepaintBoundary(
                                  child: FastestServerCard(
                                    vpnRepo: vpnRepo,
                                    onConnect: () =>
                                        vpnRepo.connectToFastestServer(),
                                    onServerDetails: () {
                                      if (vpnRepo.fastestServer != null) {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => ServerDetailsSheet(
                                            server: vpnRepo.fastestServer!,
                                            onConnect: () {
                                              Navigator.of(context).pop();
                                              vpnRepo.selectServer(
                                                vpnRepo.fastestServer!,
                                              );
                                              vpnRepo.connect();
                                            },
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                      ),

                      // ── Selected Server Card ────────────────────────────────
                      AnimatedFadeSlide(
                        delayMs: Motion.staggerStepMs * 4,
                        child: AnimatedSwitcher(
                          duration: Motion.medium,
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.12, 0),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: selectedServer != null
                              ? PressableScale(
                                  key: ValueKey(selectedServer.id),
                                  pressedScale: 0.98,
                                  child: _buildServerCard(
                                    context,
                                    vpnRepo,
                                    selectedServer,
                                    isConnected,
                                    isConnecting,
                                  ),
                                )
                              : KeyedSubtree(
                                  key: const ValueKey('no_server'),
                                  child: _buildNoServerCard(context, vpnRepo),
                                ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Animated Switcher for Live Metrics vs Spec HUD ──────
                      AnimatedFadeSlide(
                        delayMs: Motion.staggerStepMs * 5,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.06),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: isConnected
                              ? _ConnectedMetricsPanel(
                                  key: const ValueKey('metrics_panel'),
                                  vpn: vpnRepo,
                                  server: selectedServer,
                                  onSwitchServer: widget.onNavigateToServers,
                                )
                              : !isConnecting
                              ? _buildNetworkInfoCard(selectedServer)
                              : const SizedBox.shrink(
                                  key: ValueKey('connecting_spacer'),
                                ),
                        ),
                      ),

                      // ── Error banner ────────────────────────────────────────
                      AnimatedSize(
                        duration: Motion.medium,
                        curve: Curves.easeOutCubic,
                        child: isError
                            ? Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: AnimatedFadeSlide(
                                  beginScale: 0.94,
                                  child: AnimatedBuilder(
                                    animation: _shake,
                                    child: _buildErrorBanner(context, vpnRepo),
                                    builder: (context, child) {
                                      final t = _shake.value;
                                      final dx =
                                          math.sin(t * math.pi * 8) *
                                          10 *
                                          (1 - t);
                                      return Transform.translate(
                                        offset: Offset(dx, 0),
                                        child: child,
                                      );
                                    },
                                  ),
                                ),
                              )
                            : const SizedBox(width: double.infinity),
                      ),

                      const SizedBox(height: 24),

                      // ── Academic Context & Disclaimer ───────────────────────
                      Text(
                        AppConstants.publicRelayDisclaimer,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.mutedText,
                          fontSize: 10,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    VpnConnectionState state,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AppBarShield(state: state),
          const SizedBox(width: 8),
          Text(
            AppConstants.appName,
            style: AppTextStyles.headlineSm.copyWith(
              color: AppColors.primaryText,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.elevatedSurface,
              border: Border.all(color: AppColors.borderDivider),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.secondaryText,
              size: 18,
            ),
          ),
          tooltip: 'About',
          onPressed: () => _showAcademicNotice(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Server card ─────────────────────────────────────────────────────────────

  Widget _buildServerCard(
    BuildContext context,
    VpnController vpnRepo,
    dynamic server,
    bool isConnected,
    bool isConnecting,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? AppColors.connectedStatus.withValues(alpha: 0.6)
              : AppColors.borderDivider,
          width: 1.2,
        ),
        boxShadow: Motion.shadows(context, [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          if (isConnected)
            BoxShadow(
              color: AppColors.connectedStatus.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: 1,
            ),
        ]),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primaryText.withValues(alpha: 0.08),
          highlightColor: AppColors.primaryText.withValues(alpha: 0.04),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ServerDetailsSheet(
                server: server,
                onConnect: () {
                  Navigator.of(context).pop();
                  vpnRepo.selectServer(server);
                  vpnRepo.connect();
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CountryBadge(
                  countryCode: server.countryCode,
                  size: 46,
                  darkMode: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              server.country,
                              style: AppTextStyles.labelLg.copyWith(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (vpnRepo.fastestServer?.id == server.id)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.borderDivider,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.bolt_rounded,
                                    size: 11,
                                    color: AppColors.primaryText,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'FASTEST',
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: AppColors.secondaryText,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.elevatedSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.borderDivider,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                server.protocol,
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.secondaryText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppColors.mutedText,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              server.city.isNotEmpty
                                  ? server.city
                                  : server.host,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.secondaryText,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.elevatedSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderDivider,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Change',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.primaryText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoServerCard(BuildContext context, VpnController vpnRepo) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDivider, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.dns_outlined, color: AppColors.mutedText),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No server selected',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => vpnRepo.loadServers(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: AppColors.primaryBackground,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Load Servers',
              style: AppTextStyles.labelMd.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Network Info / Architecture Spec Card ──────────────────────────────────

  Widget _buildNetworkInfoCard(dynamic server) {
    return Container(
      key: const ValueKey('network_info_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDivider, width: 1.0),
        boxShadow: Motion.shadows(context, [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderDivider),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'SECURITY ARCHITECTURE',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primaryText,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.connectedStatus.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.connectedStatus.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Active Defense',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.connectedStatus,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Security Features Grid
          Row(
            children: [
              Expanded(
                child: _buildFeaturePill(
                  0,
                  Icons.lock_rounded,
                  'OpenVPN',
                  'Encrypted tunnel',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFeaturePill(
                  1,
                  Icons.vpn_lock_rounded,
                  'Public relay',
                  'Third-party operated',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildFeaturePill(
                  2,
                  Icons.verified_user_outlined,
                  'Relay logging',
                  'Operator policy applies',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFeaturePill(
                  3,
                  Icons.security_rounded,
                  'Relay DNS',
                  'Profile configured',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.borderDivider, height: 1),
          const SizedBox(height: 14),

          _buildInfoRow(
            'Tunnel Protocol',
            'OpenVPN / ${server?.protocol ?? 'UDP'}',
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Relay type', 'Community operated'),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(
    int order,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return AnimatedFadeSlide(
      delayMs: 120 + order * 70,
      beginScale: 0.9,
      offset: const Offset(0, 0.15),
      child: _buildFeaturePillBody(icon, title, subtitle),
    );
  }

  Widget _buildFeaturePillBody(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDivider, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryText),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.mutedText,
                    fontSize: 9.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, VpnController vpnRepo) {
    final err = vpnRepo.vpnError ?? "Couldn't establish the VPN connection.";
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.errorStatus.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.errorStatus,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              err,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.primaryText,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => vpnRepo.connect(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorStatus,
              foregroundColor: AppColors.pureWhite,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Retry',
              style: AppTextStyles.labelMd.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.mutedText,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showAcademicNotice(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDivider, width: 1.0),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.shield_rounded,
              color: AppColors.primaryText,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: AppTextStyles.headlineSm.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.academicContext,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Galaxy VPN demonstrates an Android client implementation '
              'utilizing Flutter and public relay nodes. No user traffic is '
              'monitored or monetized.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppConstants.publicRelayDisclaimer,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.mutedText,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: AppColors.primaryBackground,
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Understood',
              style: AppTextStyles.labelMd.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AnimatedStatusText  –  Headline + Sub-headline with AnimatedSwitcher
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedStatusText extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final bool isDisconnecting;
  final bool isError;
  final String? countryName;

  const _AnimatedStatusText({
    required this.isConnected,
    required this.isConnecting,
    required this.isDisconnecting,
    required this.isError,
    this.countryName,
  });

  String get _headline {
    if (isConnected) return 'Shield Active & Encrypted';
    if (isConnecting) {
      return countryName != null
          ? 'Connecting to $countryName…'
          : 'Establishing Secure Tunnel…';
    }
    if (isDisconnecting) return 'Disconnecting…';
    if (isError) return 'Connection Failed';
    return 'Protection Offline';
  }

  String get _subtext {
    if (isConnected) return 'All traffic routed through encrypted relay.';
    if (isConnecting) return 'Negotiating handshake with remote gateway.';
    if (isDisconnecting) return 'Tearing down the secure tunnel safely.';
    if (isError) {
      return 'Could not reach the VPN gateway. Check your connection.';
    }
    return 'Tap connect to route traffic through an encrypted relay.';
  }

  Color get _headlineColor {
    if (isConnected) return AppColors.connectedStatus;
    if (isConnecting) return AppColors.primaryText;
    if (isError) return AppColors.errorStatus;
    return AppColors.primaryText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
              child: child,
            ),
          ),
          child: Text(
            _headline,
            key: ValueKey(_headline),
            style: AppTextStyles.headlineMd.copyWith(
              color: _headlineColor,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
              child: child,
            ),
          ),
          child: Text(
            _subtext,
            key: ValueKey(_subtext),
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.secondaryText,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ConnectedMetricsPanel  –  Sleek Charcoal Metrics Display
// ─────────────────────────────────────────────────────────────────────────────

class _ConnectedMetricsPanel extends StatefulWidget {
  /// Read through [VpnController.metricsListenable]: the live readouts redraw
  /// each second on their own, without rebuilding the rest of Home.
  final VpnController vpn;
  final dynamic server;
  final VoidCallback onSwitchServer;

  const _ConnectedMetricsPanel({
    super.key,
    required this.vpn,
    required this.server,
    required this.onSwitchServer,
  });

  @override
  State<_ConnectedMetricsPanel> createState() => _ConnectedMetricsPanelState();
}

class _ConnectedMetricsPanelState extends State<_ConnectedMetricsPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final vpn = widget.vpn;
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          children: [
            // ── Metrics grid ──────────────────────────────────────────────
            RepaintBoundary(
              child: ListenableBuilder(
                listenable: vpn.metricsListenable,
                builder: (context, _) => _buildMetricsGrid(vpn),
              ),
            ),

            const SizedBox(height: 16),

            // ── Exit node card ────────────────────────────────────────────
            ListenableBuilder(
              listenable: vpn.metricsListenable,
              builder: (context, _) =>
                  _buildExitNodeCard(vpn.liveMetrics.publicIp),
            ),

            const SizedBox(height: 12),

            // ── Automatic IP rotation ─────────────────────────────────────
            const RepaintBoundary(child: IpRotationCard()),

            const SizedBox(height: 20),

            // ── Switch server button ──────────────────────────────────────
            SecondaryButton(
              text: 'Switch Relay Node',
              onPressed: widget.onSwitchServer,
              leading: const Icon(
                Icons.sync_alt_rounded,
                size: 18,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(VpnController vpn) {
    final m = vpn.liveMetrics;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        AnimatedFadeSlide(
          delayMs: 0 * Motion.staggerStepMs,
          beginScale: 0.9,
          child: _CyberMetricTile(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: m.duration ?? '00:00',
            accent: AppColors.primaryText,
          ),
        ),
        AnimatedFadeSlide(
          delayMs: 1 * Motion.staggerStepMs,
          beginScale: 0.9,
          child: _CyberMetricTile(
            icon: Icons.speed_rounded,
            label: 'Latency',
            value: widget.server?.pingDisplay ?? '—',
            accent: AppColors.connectedStatus,
          ),
        ),
        AnimatedFadeSlide(
          delayMs: 2 * Motion.staggerStepMs,
          beginScale: 0.9,
          child: _CyberMetricTile(
            icon: Icons.arrow_downward_rounded,
            label: 'Downloaded',
            value: _formatBytes(m.byteIn),
            detail:
                '${VpnLiveMetrics.formatBitRate(vpn.downloadBitsPerSecond)} now',
            accent: AppColors.secondaryText,
          ),
        ),
        AnimatedFadeSlide(
          delayMs: 3 * Motion.staggerStepMs,
          beginScale: 0.9,
          child: _CyberMetricTile(
            icon: Icons.arrow_upward_rounded,
            label: 'Uploaded',
            value: _formatBytes(m.byteOut),
            detail:
                '${VpnLiveMetrics.formatBitRate(vpn.uploadBitsPerSecond)} now',
            accent: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildExitNodeCard(String? ip) {
    final server = widget.server;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDivider, width: 1.0),
        boxShadow: Motion.shadows(context, [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RELAY PUBLIC IP',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.mutedText,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ip ?? server?.host ?? 'Encrypted Gateway',
                  style: AppTextStyles.labelLg.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.connectedStatus.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.connectedStatus.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PulsingDot(color: AppColors.connectedStatus),
                const SizedBox(width: 4),
                Text(
                  'Encrypted',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.connectedStatus,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CyberMetricTile  –  Individual Charcoal Stat Card
// ─────────────────────────────────────────────────────────────────────────────

class _CyberMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  /// Secondary line under the value, e.g. the current transfer rate.
  final String? detail;

  const _CyberMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final isLivePing = accent == AppColors.connectedStatus;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLivePing
              ? AppColors.connectedStatus.withValues(alpha: 0.35)
              : AppColors.borderDivider,
          width: 1.0,
        ),
        boxShadow: Motion.shadows(context, [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          if (isLivePing)
            BoxShadow(
              color: AppColors.connectedStatus.withValues(alpha: 0.08),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.mutedText,
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isLivePing)
                const PulsingDot(color: AppColors.connectedStatus),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: OdometerText(
              value,
              style: AppTextStyles.metricLg.copyWith(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(
              detail!,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppBarShield  –  Brand mark that reflects the live tunnel state
// ─────────────────────────────────────────────────────────────────────────────

class _AppBarShield extends StatelessWidget {
  final VpnConnectionState state;

  const _AppBarShield({required this.state});

  @override
  Widget build(BuildContext context) {
    final isConnected = state == VpnConnectionState.connected;
    final isConnecting =
        state == VpnConnectionState.connecting ||
        state == VpnConnectionState.checking;
    final isError = state == VpnConnectionState.error;

    final accent = isConnected
        ? AppColors.connectedStatus
        : isError
        ? AppColors.errorStatus
        : AppColors.primaryText;
    final icon = isConnected
        ? Icons.verified_user_rounded
        : isError
        ? Icons.gpp_maybe_rounded
        : Icons.shield_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.elevatedSurface,
        border: Border.all(
          color: isConnected || isError
              ? accent.withValues(alpha: 0.6)
              : AppColors.borderDivider,
          width: 1.0,
        ),
        boxShadow: Motion.shadows(context, [
          if (isConnected)
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ]),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isConnecting)
            const SizedBox.square(
              dimension: 26,
              child: CircularProgressIndicator(
                strokeWidth: 1.4,
                color: AppColors.secondaryText,
              ),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => RotationTransition(
              turns: Tween<double>(begin: -0.25, end: 0).animate(anim),
              child: ScaleTransition(
                scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                child: child,
              ),
            ),
            child: Icon(icon, key: ValueKey(icon), size: 14, color: accent),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OrbStage  –  Scroll parallax around the orb
// ─────────────────────────────────────────────────────────────────────────────

class _OrbStage extends StatelessWidget {
  final ScrollController scroll;
  final Widget child;

  const _OrbStage({required this.scroll, required this.child});

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.isReduced(context);

    return AnimatedBuilder(
      animation: scroll,
      child: child,
      builder: (context, child) {
        final offset = scroll.hasClients ? scroll.offset : 0.0;
        double scale = 1.0;
        double opacity = 1.0;
        double shift = 0.0;
        if (!reduced) {
          if (offset > 0) {
            final t = (offset / 400).clamp(0.0, 1.0);
            scale = 1.0 - 0.15 * t;
            opacity = 1.0 - 0.5 * t;
            shift = offset * 0.3;
          } else {
            // Pulling down gently inflates the orb.
            scale = 1.0 + 0.06 * (-offset / 120).clamp(0.0, 1.0);
          }
        }

        return Transform.translate(
          offset: Offset(0, shift),
          child: Transform.scale(
            scale: scale,
            child: Opacity(opacity: opacity, child: child),
          ),
        );
      },
    );
  }
}

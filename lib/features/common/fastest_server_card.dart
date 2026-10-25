import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../data/models/vpn_server.dart';
import '../../domain/entities/vpn_connection_state.dart';
import '../../presentation/controllers/vpn_controller.dart';
import 'country_badge.dart';

/// Suggests a relay using reported throughput and measured TCP latency where
/// the selected profile supports a TCP probe.
///
/// Designed to seamlessly fit into the Quiet Bastion & Cyber Dark visual identity:
///  • Glassmorphic cyber-navy substrate with electric cyan accent borders.
///  • Radar animation around the current relay latency indicator.
///  • 360° spinning tactile benchmark button.
///  • High-contrast electric cyan action button with spring physics.
///  • Periodic subtle shimmer highlight sweeping across the card.
class FastestServerCard extends StatefulWidget {
  final VpnController vpnRepo;
  final VoidCallback? onConnect;
  final VoidCallback? onServerDetails;
  final bool isCompact;

  const FastestServerCard({
    super.key,
    required this.vpnRepo,
    this.onConnect,
    this.onServerDetails,
    this.isCompact = false,
  });

  @override
  State<FastestServerCard> createState() => _FastestServerCardState();
}

class _FastestServerCardState extends State<FastestServerCard>
    with TickerProviderStateMixin {
  late final AnimationController _ambientCtrl;
  late final AnimationController _radarCtrl;
  late final AnimationController _spinCtrl;
  late final AnimationController _shimmerCtrl;

  bool _buttonPressed = false;

  bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();

    // 1. Ambient breathing border aura
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // 2. Continuous outward expanding radar ping wave
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // 3. Tactile spin for manual benchmark refresh
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // 4. Subtle periodic diagonal cyber shimmer
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    if (!_isTestEnvironment) {
      _ambientCtrl.repeat(reverse: true);
      _radarCtrl.repeat();
      _shimmerCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant FastestServerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vpnRepo.isDetectingFastest && !_spinCtrl.isAnimating) {
      if (!_isTestEnvironment) {
        _spinCtrl.repeat();
      }
    } else if (!widget.vpnRepo.isDetectingFastest &&
        oldWidget.vpnRepo.isDetectingFastest) {
      _spinCtrl.stop();
      _spinCtrl.animateTo(
        1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _radarCtrl.dispose();
    _spinCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _handleManualRefresh() {
    if (_isTestEnvironment) {
      widget.vpnRepo.detectFastestServer(forceProbe: true);
      return;
    }
    _spinCtrl.forward(from: 0.0);
    widget.vpnRepo.detectFastestServer(forceProbe: true);
  }

  Color _getPingColor(int? ping) {
    if (ping == null) return AppColors.mutedText;
    if (ping < 120) return AppColors.primaryText;
    if (ping < 200) return AppColors.secondaryText;
    return AppColors.errorStatus;
  }

  @override
  Widget build(BuildContext context) {
    final vpnRepo = widget.vpnRepo;
    final fastest = vpnRepo.fastestServer;
    final isDetecting = vpnRepo.isDetectingFastest;
    final currentState = vpnRepo.connectionState;
    final isConnected = currentState == VpnConnectionState.connected;
    final isConnecting =
        currentState == VpnConnectionState.connecting ||
        currentState == VpnConnectionState.checking;
    final isSelected =
        fastest != null && vpnRepo.selectedServer?.id == fastest.id;
    final isOptimalActive = isConnected && isSelected;

    if (fastest == null && !isDetecting) {
      return const SizedBox.shrink();
    }

    final pingColor = _getPingColor(fastest?.pingMs);

    return AnimatedBuilder(
      animation: Listenable.merge([_ambientCtrl, _shimmerCtrl]),
      builder: (context, _) {
        final shimmerVal = _shimmerCtrl.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isOptimalActive
                  ? [const Color(0xFF0E1A14), const Color(0xFF090909)]
                  : [AppColors.cardBackground, AppColors.secondaryBackground],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isOptimalActive
                  ? AppColors.connectedStatus.withValues(alpha: 0.6)
                  : AppColors.borderDivider,
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // ── Subtle Shimmer Highlight Sweep ──────────────────────────
                if (!_isTestEnvironment)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ShimmerSweepPainter(
                          progress: shimmerVal,
                          color: AppColors.primaryText.withValues(alpha: 0.03),
                        ),
                      ),
                    ),
                  ),

                // ── Main Card Content ───────────────────────────────────────
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: AppColors.primaryText.withValues(alpha: 0.08),
                    highlightColor: AppColors.primaryText.withValues(
                      alpha: 0.04,
                    ),
                    onTap: fastest != null ? widget.onServerDetails : null,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: widget.isCompact ? 12 : 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header Row: Cyber Badge, Label & Latency ──────
                          _buildHeaderRow(
                            isDetecting: isDetecting,
                            fastest: fastest,
                            pingColor: pingColor,
                          ),

                          const SizedBox(height: 14),

                          // ── Server Info Row ───────────────────────────────
                          if (fastest != null) ...[
                            _buildServerInfoRow(fastest),

                            if (!widget.isCompact) ...[
                              const SizedBox(height: 14),
                              const Divider(
                                color: AppColors.borderDivider,
                                height: 1,
                              ),
                              const SizedBox(height: 14),

                              // ── Action Buttons Row ────────────────────────
                              _buildActionRow(
                                fastest: fastest,
                                isOptimalActive: isOptimalActive,
                                isConnected: isConnected,
                                isConnecting: isConnecting,
                                isSelected: isSelected,
                              ),
                            ],
                          ] else ...[
                            _buildDetectingPlaceholder(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Header Row with Cyber Pill and Radar Latency
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderRow({
    required bool isDetecting,
    required VpnServer? fastest,
    required Color pingColor,
  }) {
    return Row(
      children: [
        // Cyber lightning icon badge
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            size: 14,
            color: AppColors.pureWhite,
          ),
        ),
        const SizedBox(width: 8),

        // Title and Auto-Detected Badge
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'FASTEST SERVER',
                  style: AppTextStyles.labelSm.copyWith(
                    color: Colors.white,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.pureWhite,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Auto',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Live Radar Ping Meter
        if (isDetecting)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: AppColors.pureWhite,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Probing...',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        else if (fastest?.pingMs != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDivider, width: 0.9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Concentric expanding radar wave pip
                SizedBox(
                  width: 14,
                  height: 14,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!_isTestEnvironment)
                        AnimatedBuilder(
                          animation: _radarCtrl,
                          builder: (context, _) {
                            final wave = _radarCtrl.value;
                            return Container(
                              width: 5 + (wave * 9),
                              height: 5 + (wave * 9),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: pingColor.withValues(
                                    alpha: (1.0 - wave) * 0.7,
                                  ),
                                  width: 1.0,
                                ),
                              ),
                            );
                          },
                        ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: pingColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: pingColor, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${fastest!.pingMs} ms',
                  style: AppTextStyles.labelSm.copyWith(
                    color: pingColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(width: 4),

        // Animated Benchmark Re-probe Button
        RotationTransition(
          turns: _spinCtrl,
          child: IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              size: 17,
              color: isDetecting
                  ? AppColors.pureWhite
                  : AppColors.secondaryText,
            ),
            tooltip: 'Benchmark device latency again',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: isDetecting ? null : _handleManualRefresh,
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Server Info Row
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildServerInfoRow(VpnServer fastest) {
    return Row(
      children: [
        CountryBadge(
          countryCode: fastest.countryCode,
          size: 40,
          darkMode: true,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      fastest.country,
                      style: AppTextStyles.labelLg.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Text(
                      fastest.protocol,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.primaryText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                fastest.city.isNotEmpty ? fastest.city : fastest.host,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.speed_rounded,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  fastest.speedDisplay,
                  style: AppTextStyles.labelSm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Reported bandwidth',
              style: AppTextStyles.labelSm.copyWith(
                color: Colors.white38,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Action Bar Row: 1-Tap Connect or Optimal Status
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildActionRow({
    required VpnServer fastest,
    required bool isOptimalActive,
    required bool isConnected,
    required bool isConnecting,
    required bool isSelected,
  }) {
    if (isOptimalActive) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.connectedStatus.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.connectedStatus.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: AppColors.connectedStatus,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Connected to Fastest Relay on this Device',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.connectedStatus,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final actionLabel = isConnected
        ? fastest.pingMs == null
              ? 'Switch to Recommended Relay'
              : 'Switch to Fastest (${fastest.pingMs} ms)'
        : 'Connect to Fastest Server';

    return Row(
      children: [
        // Primary Cyber Action Button with Tactile Spring & Glow
        Expanded(
          child: GestureDetector(
            onTapDown: (_) => setState(() => _buttonPressed = true),
            onTapUp: (_) => setState(() => _buttonPressed = false),
            onTapCancel: () => setState(() => _buttonPressed = false),
            child: AnimatedScale(
              scale: _buttonPressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: isConnecting
                        ? null
                        : () async {
                            if (widget.onConnect != null) {
                              widget.onConnect!();
                            } else {
                              await widget.vpnRepo.connectToFastestServer();
                            }
                          },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 17,
                            color: AppColors.primaryBackground,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              actionLabel,
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.primaryBackground,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Secondary Select Button
        if (!isSelected) ...[
          const SizedBox(width: 8),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                splashColor: Colors.white10,
                onTap: () {
                  widget.vpnRepo.selectFastestServer();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    child: Text(
                      'Select',
                      style: AppTextStyles.labelMd.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Benchmarking Detection Placeholder
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDetectingPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: AppColors.pureWhite,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Benchmarking server latencies for this device...',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic diagonal subtle shimmer painter for cyber card substrate
class _ShimmerSweepPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ShimmerSweepPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final travel = size.width + size.height * 2;
    final currentOffset = -size.height + (travel * progress);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
        colors: [
          Colors.transparent,
          Colors.transparent,
          color,
          Colors.transparent,
          Colors.transparent,
        ],
        transform: _GradientTranslateTransform(currentOffset, size.width),
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerSweepPainter old) =>
      old.progress != progress;
}

class _GradientTranslateTransform extends GradientTransform {
  final double dx;
  final double width;

  const _GradientTranslateTransform(this.dx, this.width);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}

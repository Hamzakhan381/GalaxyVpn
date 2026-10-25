import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../data/models/vpn_server.dart';
import 'country_badge.dart';
import 'motion.dart';

class ServerListTile extends StatefulWidget {
  final VpnServer server;
  final bool isSelected;

  /// True only while the tunnel is actually up through this server.
  final bool isConnected;
  final bool isFastest;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const ServerListTile({
    super.key,
    required this.server,
    this.isSelected = false,
    this.isConnected = false,
    this.isFastest = false,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  State<ServerListTile> createState() => _ServerListTileState();
}

class _ServerListTileState extends State<ServerListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _starCtrl;
  late Animation<double> _starAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _starAnim = Tween<double>(
      begin: 1.0,
      end: 1.35,
    ).animate(CurvedAnimation(parent: _starCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _starCtrl.dispose();
    super.dispose();
  }

  void _handleFavorite() {
    _starCtrl.forward(from: 0.0).then((_) {
      if (mounted) _starCtrl.reverse();
    });
    widget.onFavoriteTap();
  }

  Color _getPingColor(int? ping) {
    if (ping == null) return AppColors.mutedText;
    if (ping < 90) return AppColors.primaryText; // clean white
    if (ping < 180) return AppColors.secondaryText; // soft silver grey
    return AppColors.errorStatus; // restrained red
  }

  @override
  Widget build(BuildContext context) {
    final server = widget.server;
    final isSelected = widget.isSelected;
    final isConnected = widget.isConnected;
    final pingColor = _getPingColor(server.pingMs);

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected || isConnected
              ? AppColors.elevatedSurface
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isConnected
                ? AppColors.connectedStatus.withValues(alpha: 0.75)
                : isSelected
                ? AppColors.primaryText
                : AppColors.borderDivider,
            width: isSelected || isConnected ? 1.5 : 1.0,
          ),
          boxShadow: Motion.shadows(context, [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            splashColor: AppColors.primaryText.withValues(alpha: 0.08),
            highlightColor: AppColors.primaryText.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CountryBadge(
                    countryCode: server.countryCode,
                    size: 42,
                    darkMode: true,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                server.country,
                                style: AppTextStyles.labelLg.copyWith(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // A compact bolt keeps the country name readable;
                            // a worded badge here squeezed it to nothing.
                            if (widget.isFastest) ...[
                              const SizedBox(width: 6),
                              Semantics(
                                label: 'Fastest server',
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.borderDivider,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.bolt_rounded,
                                    size: 11,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isConnected) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.connectedStatus,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Flexible(
                              child: Text(
                                isConnected
                                    ? 'Connected'
                                    : server.city.isNotEmpty
                                    ? server.city
                                    : server.host,
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: isConnected
                                      ? AppColors.connectedStatus
                                      : AppColors.secondaryText,
                                  fontSize: 12,
                                  fontWeight: isConnected
                                      ? FontWeight.w600
                                      : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.elevatedSurface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppColors.borderDivider,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                server.protocol,
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.secondaryText,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Latency pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.elevatedSurface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.borderDivider,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: pingColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          server.pingDisplay,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.primaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Animated Favorite star
                  ScaleTransition(
                    scale: _starAnim,
                    child: IconButton(
                      icon: Icon(
                        server.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: server.isFavorite
                            ? AppColors.primaryText
                            : AppColors.mutedText,
                        size: 22,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: _handleFavorite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

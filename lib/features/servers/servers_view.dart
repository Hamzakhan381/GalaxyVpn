import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/platform/haptics.dart';
import '../../data/models/vpn_server.dart';
import '../../domain/entities/server_sort_option.dart';
import '../../domain/entities/vpn_connection_state.dart';
import '../../presentation/controllers/vpn_controller.dart';
import '../common/cyber_background.dart';
import '../common/empty_state.dart';
import '../common/fastest_server_card.dart';
import '../common/motion.dart';
import '../common/server_list_tile.dart';
import 'server_details_sheet.dart';

class ServersView extends StatefulWidget {
  final VoidCallback? onServerConnected;

  const ServersView({super.key, this.onServerConnected});

  @override
  State<ServersView> createState() => _ServersViewState();
}

class _ServersViewState extends State<ServersView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCountry = 'All Countries';
  String _selectedProtocol = 'All Protocols';
  ServerSortOption _sortOption = ServerSortOption.bestAvailable;

  /// Staggered list entrance only plays until the user starts scrolling,
  /// so rows recycled back into view don't re-stagger.
  bool _listScrolled = false;
  bool _showFavoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnController>(
      builder: (context, vpnRepo, _) {
        if (vpnRepo.isLoadingServers && vpnRepo.countryServers.isEmpty) {
          return const Scaffold(
            backgroundColor: AppColors.primaryBackground,
            body: CyberBackground(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryText),
              ),
            ),
          );
        }

        if (vpnRepo.serverLoadError != null && vpnRepo.countryServers.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.primaryBackground,
            appBar: AppBar(
              title: Text(
                'Relay Servers',
                style: AppTextStyles.headlineSm.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ),
            body: CyberBackground(
              child: ErrorState(
                title: 'Server List Unavailable',
                message: 'Could not retrieve the relay registry. Check your network connection and retry.',
                onRetry: () => vpnRepo.loadServers(forceRefresh: true),
              ),
            ),
          );
        }

        // Get unique countries for filter
        final countries = [
          'All Countries',
          ...vpnRepo.countryServers.map((s) => s.country).toSet().toList()
            ..sort(),
        ];

        // Filter & Sort
        var filtered = vpnRepo.serverService.filterAndSort(
          servers: vpnRepo.countryServers,
          query: _searchController.text,
          countryFilter: _selectedCountry,
          protocolFilter: _selectedProtocol,
          sortOption: _sortOption,
        );

        if (_showFavoritesOnly) {
          filtered = filtered.where((s) => s.isFavorite).toList();
        }

        return Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Relay Servers',
              style: AppTextStyles.headlineSm.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _showFavoritesOnly
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: _showFavoritesOnly
                      ? AppColors.primaryText
                      : AppColors.secondaryText,
                ),
                tooltip: 'Favorites Only',
                onPressed: () {
                  setState(() => _showFavoritesOnly = !_showFavoritesOnly);
                },
              ),
              PopupMenuButton<ServerSortOption>(
                icon: const Icon(
                  Icons.sort_rounded,
                  color: AppColors.secondaryText,
                ),
                tooltip: 'Sort Servers',
                color: AppColors.elevatedSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.borderDivider),
                ),
                onSelected: (opt) => setState(() => _sortOption = opt),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: ServerSortOption.bestAvailable,
                    child: Text(
                      'Best Available (Performance)',
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                  ),
                  const PopupMenuItem(
                    value: ServerSortOption.lowestLatency,
                    child: Text(
                      'Lowest Latency (Fastest ms)',
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                  ),
                  const PopupMenuItem(
                    value: ServerSortOption.highestSpeed,
                    child: Text(
                      'Highest Speed (Mbps)',
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                  ),
                  const PopupMenuItem(
                    value: ServerSortOption.highestQuality,
                    child: Text(
                      'Highest Score',
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                  ),
                  const PopupMenuItem(
                    value: ServerSortOption.favoritesFirst,
                    child: Text(
                      'Favorites First',
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: CyberBackground(
            child: RefreshIndicator(
              color: AppColors.primaryText,
              backgroundColor: AppColors.elevatedSurface,
              onRefresh: () => vpnRepo.loadServers(forceRefresh: true),
              child: Column(
                children: [
                  // Search Bar with charcoal container
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 14,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        hintText: 'Search by country, city, or host...',
                        hintStyle: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primaryText,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppColors.secondaryText,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.borderDivider,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.borderDivider,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primaryText,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Horizontal Filters with Charcoal Pills
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildChip(
                          label: _selectedProtocol,
                          isSelected: _selectedProtocol != 'All Protocols',
                          onTap: () => _showProtocolPicker(context),
                        ),
                        const SizedBox(width: 8),
                        _buildChip(
                          label: _selectedCountry,
                          isSelected: _selectedCountry != 'All Countries',
                          onTap: () => _showCountryPicker(context, countries),
                        ),
                        const SizedBox(width: 8),
                        if (_showFavoritesOnly)
                          _buildChip(
                            label: '★ Favorites',
                            isSelected: true,
                            onTap: () =>
                                setState(() => _showFavoritesOnly = false),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Fastest Server Auto-Detect Hero Card
                  if (_searchController.text.isEmpty &&
                      _selectedCountry == 'All Countries' &&
                      _selectedProtocol == 'All Protocols' &&
                      !_showFavoritesOnly &&
                      (vpnRepo.fastestServer != null ||
                          vpnRepo.isDetectingFastest))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FastestServerCard(
                        isCompact: true,
                        vpnRepo: vpnRepo,
                        onConnect: () {
                          vpnRepo.connectToFastestServer();
                          widget.onServerConnected?.call();
                        },
                        onServerDetails: () {
                          if (vpnRepo.fastestServer != null) {
                            _showServerDetails(
                              context,
                              vpnRepo,
                              vpnRepo.fastestServer!,
                            );
                          }
                        },
                      ),
                    ),

                  // Server Count Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TweenAnimationBuilder<int>(
                              tween: IntTween(begin: 0, end: filtered.length),
                              duration: Motion.slow,
                              curve: Curves.easeOutCubic,
                              builder: (context, count, _) => Text(
                                '$count ${count == 1 ? 'COUNTRY' : 'COUNTRIES'} AVAILABLE',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.secondaryText,
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _sortOptionToString(_sortOption),
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Animated Server List
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: Motion.medium,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: filtered.isEmpty
                          ? EmptyState(
                              key: const ValueKey('servers_empty'),
                              icon: Icons.search_off,
                              title: 'No Relays Found',
                              message: 'Try adjusting your search query or filter settings.',
                              actionText: 'Reset Filters',
                              onAction: () {
                                setState(() {
                                  _searchController.clear();
                                  _selectedCountry = 'All Countries';
                                  _selectedProtocol = 'All Protocols';
                                  _showFavoritesOnly = false;
                                });
                              },
                            )
                          : NotificationListener<ScrollStartNotification>(
                              key: const ValueKey('servers_list'),
                              onNotification: (_) {
                                _listScrolled = true;
                                return false;
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final server = filtered[index];
                                  final isSelected =
                                      vpnRepo.selectedServer?.id == server.id;
                                  final isFastest =
                                      vpnRepo.fastestServer?.id == server.id;

                                  return AnimatedFadeSlide(
                                    key: ValueKey(server.id),
                                    delayMs: !_listScrolled && index < 8
                                        ? index * Motion.staggerStepMs
                                        : 0,
                                    offset: const Offset(0, 0.25),
                                    child: ServerListTile(
                                      server: server,
                                      isSelected: isSelected,
                                      isConnected:
                                          isSelected &&
                                          vpnRepo.connectionState ==
                                              VpnConnectionState.connected,
                                      isFastest: isFastest,
                                      onFavoriteTap: () {
                                        Haptics.tick();
                                        vpnRepo.toggleFavorite(server.id);
                                      },
                                      onTap: () {
                                        _showServerDetails(
                                          context,
                                          vpnRepo,
                                          server,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showServerDetails(
    BuildContext context,
    VpnController vpnRepo,
    VpnServer server,
  ) {
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
          widget.onServerConnected?.call();
        },
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.elevatedSurface
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primaryText : AppColors.borderDivider,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: isSelected
                    ? AppColors.primaryText
                    : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: isSelected
                  ? AppColors.primaryText
                  : AppColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  void _showProtocolPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.elevatedSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.borderDivider),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(
                'All Protocols',
                style: TextStyle(
                  color: _selectedProtocol == 'All Protocols'
                      ? AppColors.primaryText
                      : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: _selectedProtocol == 'All Protocols'
                  ? const Icon(Icons.check, color: AppColors.primaryText)
                  : null,
              onTap: () {
                setState(() => _selectedProtocol = 'All Protocols');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: Text(
                'OpenVPN (UDP)',
                style: TextStyle(
                  color: _selectedProtocol == 'UDP'
                      ? AppColors.primaryText
                      : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: _selectedProtocol == 'UDP'
                  ? const Icon(Icons.check, color: AppColors.primaryText)
                  : null,
              onTap: () {
                setState(() => _selectedProtocol = 'UDP');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: Text(
                'OpenVPN (TCP)',
                style: TextStyle(
                  color: _selectedProtocol == 'TCP'
                      ? AppColors.primaryText
                      : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: _selectedProtocol == 'TCP'
                  ? const Icon(Icons.check, color: AppColors.primaryText)
                  : null,
              onTap: () {
                setState(() => _selectedProtocol = 'TCP');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context, List<String> countries) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.elevatedSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.borderDivider),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: countries.length,
                itemBuilder: (ctx, idx) {
                  final c = countries[idx];
                  final isSelected = _selectedCountry == c;
                  return ListTile(
                    title: Text(
                      c,
                      style: AppTextStyles.labelLg.copyWith(
                        color: isSelected
                            ? AppColors.primaryText
                            : AppColors.secondaryText,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primaryText)
                        : null,
                    onTap: () {
                      setState(() => _selectedCountry = c);
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sortOptionToString(ServerSortOption opt) {
    switch (opt) {
      case ServerSortOption.bestAvailable:
        return 'Sorted: Best';
      case ServerSortOption.highestSpeed:
        return 'Sorted: Highest Speed';
      case ServerSortOption.lowestLatency:
        return 'Sorted: Lowest Ping';
      case ServerSortOption.highestQuality:
        return 'Sorted: Quality';
      case ServerSortOption.favoritesFirst:
        return 'Sorted: Favorites';
    }
  }
}

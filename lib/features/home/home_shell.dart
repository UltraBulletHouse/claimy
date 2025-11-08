import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import 'package:claimy/core/localization/localization_extensions.dart';
import 'package:claimy/core/theme/app_colors.dart';
import 'package:claimy/core/utils/string_utils.dart';
import 'package:claimy/features/new_case/new_case_screen.dart';
import 'package:claimy/state/app_state.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

enum _MainMenuAction { signOut, languageEnglish, languagePolish }

class _HomeShellState extends State<HomeShell> {
  late HomeLanding _currentView;

  @override
  void initState() {
    super.initState();
    _currentView = context.read<AppState>().landingPreference;
  }

  void _openNewCase() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const NewCaseScreen(),
        fullscreenDialog: true,
      ),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.claimSubmitted)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final bool showRewards = _currentView == HomeLanding.rewards;
    final unread = appState.cases.where((c) => c.hasUnreadUpdates).length;
    final firstName = appState.greetingName;
    final locale = appState.locale;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 6, bottom: 6),
        child: _NewClaimButton(onPressed: _openNewCase),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: -130,
                right: -90,
                child: _HomeAccentOrb(
                  size: 280,
                  colors: [
                    Color(0x443568FF),
                    Color(0x123568FF),
                    Colors.transparent,
                  ],
                ),
              ),
              const Positioned(
                bottom: -150,
                left: -60,
                child: _HomeAccentOrb(
                  size: 320,
                  colors: [
                    Color(0x33FF7A59),
                    Color(0x11FF7A59),
                    Colors.transparent,
                  ],
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HomeHeader(
                        firstName: firstName,
                        currentView: _currentView,
                        unreadCount: unread,
                        onViewChanged: (view) {
                          setState(() => _currentView = view);
                        },
                        onNotificationsTap: () {
                          final unreadCount = appState.cases
                              .where((c) => c.hasUnreadUpdates)
                              .length;
                          final message = context.l10n.homeUnreadCases(
                            unreadCount,
                          );
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        },
                        onMenuSelected: (action) {
                          switch (action) {
                            case _MainMenuAction.signOut:
                              context.read<AppState>().signOut();
                              break;
                            case _MainMenuAction.languageEnglish:
                              context.read<AppState>().setLocale(
                                const Locale('en'),
                              );
                              break;
                            case _MainMenuAction.languagePolish:
                              context.read<AppState>().setLocale(
                                const Locale('pl'),
                              );
                              break;
                          }
                        },
                        showRewards: showRewards,
                        locale: locale,
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: fadeColor(AppColors.textPrimary, 0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: fadeColor(Colors.black, 0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 22),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: Padding(
                                key: ValueKey(showRewards),
                                padding: const EdgeInsets.only(top: 12),
                                child: showRewards
                                    ? const RewardsView(
                                        key: ValueKey('rewards'),
                                      )
                                    : const CasesView(key: ValueKey('cases')),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewClaimButton extends StatelessWidget {
  const _NewClaimButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconBackground = Colors.white.withOpacity(0.22);
    final borderColor = fadeColor(AppColors.primary, 0.28);

    return Material(
      color: Colors.transparent,
      elevation: 10,
      shadowColor: fadeColor(AppColors.primary, 0.28),
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A74FF), Color(0xFF6C9BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: iconBackground,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  context.l10n.newClaim,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.firstName,
    required this.currentView,
    required this.unreadCount,
    required this.onViewChanged,
    required this.onNotificationsTap,
    required this.onMenuSelected,
    required this.showRewards,
    required this.locale,
  });

  final String firstName;
  final HomeLanding currentView;
  final int unreadCount;
  final ValueChanged<HomeLanding> onViewChanged;
  final VoidCallback onNotificationsTap;
  final ValueChanged<_MainMenuAction> onMenuSelected;
  final bool showRewards;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.homeGreeting(firstName),
                    style: textTheme.titleMedium?.copyWith(
                      color: fadeColor(AppColors.textPrimary, 0.7),
                    ),
                  ),
                  if (showRewards) const SizedBox(height: 8),
                ],
              ),
            ),
            _NotificationButton(
              unreadCount: unreadCount,
              onPressed: onNotificationsTap,
            ),
            const SizedBox(width: 8),
            PopupMenuButton<_MainMenuAction>(
              onSelected: onMenuSelected,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              itemBuilder: (context) {
                final languageCode = locale.languageCode;
                return [
                  PopupMenuItem<_MainMenuAction>(
                    value: _MainMenuAction.languageEnglish,
                    child: Row(
                      children: [
                        if (languageCode == 'en')
                          const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppColors.primary,
                          )
                        else
                          const SizedBox(width: 18, height: 18),
                        const SizedBox(width: 8),
                        Text(context.l10n.languageEnglish),
                      ],
                    ),
                  ),
                  PopupMenuItem<_MainMenuAction>(
                    value: _MainMenuAction.languagePolish,
                    child: Row(
                      children: [
                        if (languageCode == 'pl')
                          const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppColors.primary,
                          )
                        else
                          const SizedBox(width: 18, height: 18),
                        const SizedBox(width: 8),
                        Text(context.l10n.languagePolish),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<_MainMenuAction>(
                    value: _MainMenuAction.signOut,
                    child: Text(context.l10n.signOut),
                  ),
                ];
              },
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _HomeViewToggle(currentView: currentView, onViewChanged: onViewChanged),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeViewToggle extends StatelessWidget {
  const _HomeViewToggle({
    required this.currentView,
    required this.onViewChanged,
  });

  final HomeLanding currentView;
  final ValueChanged<HomeLanding> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: fadeColor(AppColors.textPrimary, 0.08)),
        boxShadow: [
          BoxShadow(
            color: fadeColor(Colors.black, 0.08),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          _ToggleChip(
            label: context.l10n.tabCases,
            selected: currentView == HomeLanding.cases,
            onTap: () => onViewChanged(HomeLanding.cases),
            textTheme: textTheme,
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: context.l10n.tabRewards,
            selected: currentView == HomeLanding.rewards,
            onTap: () => onViewChanged(HomeLanding.rewards),
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.textTheme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      AppColors.primary,
                      darkenColor(AppColors.primary, 0.1),
                    ],
                  )
                : null,
            color: selected ? null : Colors.transparent,
          ),
          child: Text(
            label,
            style: textTheme.titleMedium?.copyWith(
              color: selected
                  ? Colors.white
                  : fadeColor(AppColors.textPrimary, 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeAccentOrb extends StatelessWidget {
  const _HomeAccentOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: colors,
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}

class CasesView extends StatefulWidget {
  const CasesView({super.key});

  @override
  State<CasesView> createState() => _CasesViewState();
}

class _CasesViewState extends State<CasesView> {
  CaseStatus? _statusFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final cases = appState.cases;
    final bool isLoading = appState.isLoadingCases;
    final String? loadError = appState.casesError;

    if (isLoading && cases.isEmpty) {
      return const _CasesLoadingState();
    }

    if (!isLoading &&
        loadError != null &&
        loadError.isNotEmpty &&
        cases.isEmpty) {
      return _CasesErrorState(
        message: loadError,
        onRetry: () => context.read<AppState>().refreshCasesFromServer(),
      );
    }

    final query = _searchController.text.toLowerCase();
    final filtered = cases.where((caseModel) {
      final matchesStatus =
          _statusFilter == null || caseModel.status == _statusFilter;
      final matchesQuery =
          query.isEmpty ||
          caseModel.productName.toLowerCase().contains(query) ||
          caseModel.storeName.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();

    final filterConfigs = <_FilterConfig>[
      _FilterConfig(
        label: context.l10n.filterAllCases,
        icon: Icons.filter_list_rounded,
        accent: AppColors.primary,
        selected: _statusFilter == null,
        onTap: () => setState(() => _statusFilter = null),
      ),
      ...CaseStatus.values.map(
        (status) => _FilterConfig(
          label: status.label(context.l10n),
          icon: status.icon,
          accent: status.color,
          selected: _statusFilter == status,
          onTap: () => setState(() => _statusFilter = status),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: context.l10n.casesSearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Keep the filter pills tight while still spreading across the row.
              const spacing = 10.0;
              const maxTileWidth = 160.0;
              int columns = (constraints.maxWidth / maxTileWidth).ceil();
              if (columns < 1) {
                columns = 1;
              } else if (columns > 6) {
                columns = 6;
              }

              final double totalSpacing = spacing * (columns - 1);
              final double buttonWidth =
                  (constraints.maxWidth - totalSpacing) / columns;

              final bool compact = buttonWidth <= 120;

              return Wrap(
                spacing: spacing,
                runSpacing: compact ? 6 : 8,
                children: filterConfigs.map((config) {
                  return SizedBox(
                    width: buttonWidth,
                    child: _CaseFilterButton(
                      label: config.label,
                      icon: config.icon,
                      accent: config.accent,
                      selected: config.selected,
                      onTap: config.onTap,
                      compact: compact,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (isLoading && cases.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(
                  title: context.l10n.casesEmptyTitle,
                  subtitle: context.l10n.casesEmptyBody,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final caseModel = filtered[index];
                    return CaseCard(caseModel: caseModel);
                  },
                ),
        ),
      ],
    );
  }
}

class _CaseFilterButton extends StatelessWidget {
  const _CaseFilterButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Gradient? gradient = selected
        ? LinearGradient(
            colors: [accent, Color.lerp(accent, Colors.white, 0.25)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;
    final Color borderColor = selected
        ? fadeColor(accent, 0.32)
        : fadeColor(AppColors.textPrimary, 0.12);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: selected ? null : Colors.white,
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 6 : 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: compact ? 16 : 18,
                  color: selected ? Colors.white : accent,
                ),
                SizedBox(width: compact ? 6 : 8),
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : fadeColor(AppColors.textPrimary, 0.85),
                    fontSize: compact
                        ? (textTheme.bodySmall?.fontSize ?? 12.0)
                        : (textTheme.bodyMedium?.fontSize ?? 14.0),
                    letterSpacing: compact ? 0 : 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CasesLoadingState extends StatefulWidget {
  const _CasesLoadingState();

  @override
  State<_CasesLoadingState> createState() => _CasesLoadingStateState();
}

class _CasesLoadingStateState extends State<_CasesLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _pulse = Tween<double>(begin: 0.94, end: 1.04).animate(curve);
    _fade = Tween<double>(begin: 0.45, end: 1.0).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _pulse,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    fadeColor(AppColors.primary, 0.16),
                    fadeColor(AppColors.primary, 0.04),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: fadeColor(AppColors.primary, 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: fadeColor(AppColors.textPrimary, 0.06),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Center(
                  child: SizedBox(
                    height: 26,
                    width: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            context.l10n.caseSyncTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          FadeTransition(
            opacity: _fade,
            child: Text(
              context.l10n.caseSyncBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fadeColor(AppColors.textPrimary, 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _CasesErrorState extends StatelessWidget {
  const _CasesErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: fadeColor(AppColors.danger, 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.danger.withOpacity(0.9),
                  size: 36,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.caseSyncErrorTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fadeColor(AppColors.textPrimary, 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.l10n.tryAgain),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterConfig {
  const _FilterConfig({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
}

enum VoucherFilter { all, unused, expired }

class RewardsView extends StatefulWidget {
  const RewardsView({super.key});

  @override
  State<RewardsView> createState() => _RewardsViewState();
}

class _RewardsViewState extends State<RewardsView> {
  VoucherFilter _filter = VoucherFilter.all;

  @override
  Widget build(BuildContext context) {
    final allVouchers = context.watch<AppState>().vouchers;
    final now = DateTime.now();

    // Apply filter
    final filteredVouchers = allVouchers.where((v) {
      switch (_filter) {
        case VoucherFilter.unused:
          return !v.used;
        case VoucherFilter.expired:
          return v.expiration.isBefore(now);
        case VoucherFilter.all:
          return true;
      }
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: fadeColor(Colors.black, 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.rewardsIntro,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: fadeColor(AppColors.textPrimary, 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Filter chips
        if (allVouchers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _VoucherFilterChip(
                  label: 'All',
                  icon: Icons.grid_view_rounded,
                  selected: _filter == VoucherFilter.all,
                  onTap: () => setState(() => _filter = VoucherFilter.all),
                  count: allVouchers.length,
                ),
                const SizedBox(width: 8),
                _VoucherFilterChip(
                  label: 'Unused',
                  icon: Icons.circle_outlined,
                  selected: _filter == VoucherFilter.unused,
                  onTap: () => setState(() => _filter = VoucherFilter.unused),
                  count: allVouchers.where((v) => !v.used).length,
                  accent: AppColors.success,
                ),
                const SizedBox(width: 8),
                _VoucherFilterChip(
                  label: 'Expired',
                  icon: Icons.schedule_rounded,
                  selected: _filter == VoucherFilter.expired,
                  onTap: () => setState(() => _filter = VoucherFilter.expired),
                  count: allVouchers
                      .where((v) => v.expiration.isBefore(now))
                      .length,
                  accent: AppColors.danger,
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: allVouchers.isEmpty
              ? _RewardsEmptyState()
              : filteredVouchers.isEmpty
              ? _EmptyState(
                  title: 'No vouchers found',
                  subtitle: _filter == VoucherFilter.unused
                      ? 'All vouchers have been used'
                      : _filter == VoucherFilter.expired
                      ? 'No expired vouchers'
                      : 'No vouchers available',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filteredVouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = filteredVouchers[index];
                    return VoucherCard(
                      voucher: voucher,
                      key: ValueKey(voucher.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _VoucherFilterChip extends StatelessWidget {
  const _VoucherFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.count,
    this.accent,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int count;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? AppColors.primary;
    final borderRadius = BorderRadius.circular(14);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? accentColor : Colors.white,
              borderRadius: borderRadius,
              border: Border.all(
                color: selected
                    ? accentColor
                    : fadeColor(AppColors.textPrimary, 0.15),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? Colors.white
                      : fadeColor(AppColors.textPrimary, 0.6),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : fadeColor(AppColors.textPrimary, 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? fadeColor(Colors.white, 0.3)
                        : fadeColor(AppColors.textPrimary, 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : fadeColor(AppColors.textPrimary, 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    fadeColor(AppColors.accent, 0.15),
                    fadeColor(AppColors.accent, 0.05),
                  ],
                ),
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                size: 56,
                color: fadeColor(AppColors.accent, 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.rewardsEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.rewardsEmptyBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: fadeColor(AppColors.textPrimary, 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class CaseCard extends StatelessWidget {
  const CaseCard({super.key, required this.caseModel});

  final CaseModel caseModel;

  @override
  Widget build(BuildContext context) {
    final highlight = caseModel.hasUnreadUpdates;
    final requiresInfo = caseModel.requiresAdditionalInfo;
    final Color borderColor = highlight
        ? fadeColor(AppColors.primary, 0.35)
        : requiresInfo
        ? fadeColor(AppColors.warning, 0.32)
        : fadeColor(AppColors.textPrimary, 0.12);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CaseDetailScreen(caseId: caseModel.id),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: fadeColor(Colors.black, highlight ? 0.12 : 0.06),
              blurRadius: highlight ? 18 : 12,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: caseModel.productImageUrl != null
                        ? Image.network(
                            caseModel.productImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => CircleAvatar(
                              backgroundColor: fadeColor(
                                AppColors.primary,
                                0.1,
                              ),
                              child: Text(
                                toInitial(caseModel.storeName),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor: fadeColor(AppColors.primary, 0.1),
                            child: Text(
                              toInitial(caseModel.storeName),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caseModel.productName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caseModel.storeName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: fadeColor(AppColors.textPrimary, 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill(status: caseModel.status),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: fadeColor(AppColors.textPrimary, 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.caseUpdated(caseModel.lastUpdated),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: fadeColor(AppColors.textPrimary, 0.6),
                  ),
                ),
                const Spacer(),
                if (highlight)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: fadeColor(AppColors.accent, 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.caseNewUpdate,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (requiresInfo) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: fadeColor(AppColors.warning, 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.caseNeedsInfo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: darkenColor(AppColors.warning),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final CaseStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: status.color),
          const SizedBox(width: 6),
          Text(
            status.label(context.l10n),
            style: TextStyle(color: status.color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().markCaseUpdatesRead(widget.caseId);
    });
  }

  void _answerQuestion(String response) {
    context.read<AppState>().respondToAdditionalInfoServer(
      widget.caseId,
      response: response,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.infoResponseNoted(response))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caseModel = context.select<AppState, CaseModel?>(
      (state) => state.caseById(widget.caseId),
    );

    if (caseModel == null) {
      return Scaffold(body: Center(child: Text(context.l10n.caseNotFound)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(caseModel.productName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: caseModel.productImageUrl != null
                              ? Image.network(
                                  caseModel.productImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => CircleAvatar(
                                    backgroundColor: fadeColor(
                                      AppColors.primary,
                                      0.1,
                                    ),
                                    child: Text(
                                      toInitial(caseModel.storeName),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: fadeColor(
                                    AppColors.primary,
                                    0.1,
                                  ),
                                  child: Text(
                                    toInitial(caseModel.storeName),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              caseModel.storeName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            Text(
                              context.l10n.caseCreated(caseModel.createdAt),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: fadeColor(
                                      AppColors.textPrimary,
                                      0.6,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      StatusPill(status: caseModel.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flag_rounded,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.l10n.caseLastUpdate(caseModel.lastUpdated),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: fadeColor(AppColors.textPrimary, 0.7),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // NEW: Show all pending requests
          if (caseModel.pendingRequests.isNotEmpty)
            ...caseModel.pendingRequests.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PendingRequestCard(
                  request: request,
                  caseId: caseModel.id,
                  hasResponse: caseModel.hasResponse(request.id),
                ),
              ),
            ),
          // Legacy: Show old-style card if using legacy fields
          if (caseModel.requiresAdditionalInfo &&
              caseModel.pendingRequests.isEmpty)
            AdditionalInfoCard(
              question: caseModel.pendingQuestion!,
              requiresFile: caseModel.requiresFile,
              onSubmit: (response, attachmentBytes) =>
                  context.read<AppState>().respondToAdditionalInfoServer(
                    caseModel.id,
                    response: response,
                    attachment: attachmentBytes,
                  ),
              onAnswer: (response) =>
                  context.read<AppState>().respondToAdditionalInfoServer(
                    caseModel.id,
                    response: response,
                  ),
            ),
          const SizedBox(height: 16),
          Text(
            context.l10n.statusHistory,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(caseModel.history.length, (index) {
            final entry = caseModel.history[index];
            final isLast = index == caseModel.history.length - 1;
            return TimelineEntry(entry: entry, isLast: isLast);
          }),
          const SizedBox(height: 16),
          if (caseModel.receiptImageUrl != null &&
              caseModel.receiptImageUrl!.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.receiptImage,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.receiptHelp,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final url = caseModel.receiptImageUrl!;
                            final uri = Uri.parse(url);
                            if (!await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            )) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.couldNotOpen(url)),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: Text(context.l10n.open),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final url = caseModel.receiptImageUrl!;
                            await Clipboard.setData(ClipboardData(text: url));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.l10n.receiptLinkCopied),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: Text(context.l10n.copy),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TimelineEntry extends StatelessWidget {
  const TimelineEntry({super.key, required this.entry, required this.isLast});

  final CaseUpdate entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final sourceLabel = entry.isCustomerAction
        ? context.l10n.timelineYou
        : context.l10n.timelineSupport;
    final timestampLabel = context.l10n.formatMediumDate(entry.timestamp);
    final message = entry.status.localizedNote(context.l10n, entry.note);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: entry.status.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(entry.status.icon, color: entry.status.color),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 48,
                  color: darkenColor(AppColors.surface, 0.1),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: fadeColor(Colors.black, 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$sourceLabel • $timestampLabel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: fadeColor(AppColors.textPrimary, 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdditionalInfoCard extends StatefulWidget {
  const AdditionalInfoCard({
    super.key,
    required this.question,
    required this.onSubmit,
    this.requiresFile = false,
    required this.onAnswer,
  });

  final String question;
  final bool requiresFile;
  final void Function(String response, Uint8List? attachmentBytes) onSubmit;
  final void Function(String response) onAnswer;

  @override
  State<AdditionalInfoCard> createState() => _AdditionalInfoCardState();
}

class _AdditionalInfoCardState extends State<AdditionalInfoCard> {
  final _controller = TextEditingController();
  Uint8List? _attachmentBytes;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        // 10 MB limit
        if (bytes.length > 10 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.imageSizeMessage)),
          );
          return;
        }
        setState(() => _attachmentBytes = bytes);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.filePickFailed(e.toString()))),
      );
    }
  }

  Future<void> _submit() async {
    final answer = _controller.text.trim();
    if (answer.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.answerRequired)));
      return;
    }
    if (widget.requiresFile && _attachmentBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.fileRequired)));
      return;
    }
    setState(() => _submitting = true);
    try {
      await Future.sync(() => widget.onSubmit(answer, _attachmentBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.infoReceived)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: fadeColor(AppColors.warning, 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.question,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: () => widget.onAnswer('Yes'),
                child: Text(context.l10n.yes),
              ),
              ElevatedButton(
                onPressed: () => widget.onAnswer('No'),
                child: Text(context.l10n.no),
              ),
              OutlinedButton.icon(
                onPressed: () => widget.onAnswer('Uploaded photo'),
                icon: const Icon(Icons.photo_camera_rounded),
                label: Text(context.l10n.uploadPhoto),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VoucherCard extends StatefulWidget {
  const VoucherCard({super.key, required this.voucher});

  final Voucher voucher;

  @override
  State<VoucherCard> createState() => _VoucherCardState();
}

class _VoucherCardState extends State<VoucherCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.voucher.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.voucherCopied),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleUsed() async {
    final appState = context.read<AppState>();
    // Animate the toggle
    await _controller.forward();
    await appState.toggleVoucherUsed(widget.voucher.id);
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expiresIn = widget.voucher.expiration.difference(now).inDays;
    final isExpired = widget.voucher.expiration.isBefore(now);
    final expiryLabel = isExpired
        ? context.l10n.voucherExpired
        : context.l10n.voucherExpires(expiresIn);

    final highlight = !widget.voucher.used && !isExpired;
    const readyAccent = Color(
      0xFFFFB347,
    ); // midway orange/yellow for ready vouchers
    final Color borderColor = highlight
        ? fadeColor(readyAccent, 0.5)
        : isExpired
        ? fadeColor(AppColors.danger, 0.35)
        : fadeColor(AppColors.textPrimary, 0.15);
    final Color mutedText = fadeColor(AppColors.textPrimary, 0.65);
    final Color accent = isExpired
        ? AppColors.danger
        : widget.voucher.used
        ? AppColors.success
        : readyAccent;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: fadeColor(
                  highlight ? readyAccent : Colors.black,
                  highlight ? 0.2 : 0.04,
                ),
                blurRadius: highlight ? 22 : 14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: fadeColor(AppColors.primary, 0.08),
                        ),
                        child: Center(
                          child: Text(
                            toInitial(widget.voucher.storeName),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.voucher.storeName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.voucher.amountLabel,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: mutedText),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _VoucherStatusChip(
                        icon: isExpired
                            ? Icons.timer_off_rounded
                            : widget.voucher.used
                            ? Icons.verified_rounded
                            : Icons.flash_on_rounded,
                        label: isExpired
                            ? context.l10n.voucherExpired
                            : widget.voucher.used
                            ? context.l10n.voucherRedeemed
                            : context.l10n.voucherReadyToUse,
                        background: fadeColor(accent, 0.12),
                        foreground: accent,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: isExpired ? null : _toggleUsed,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isExpired
                                  ? fadeColor(AppColors.textPrimary, 0.2)
                                  : accent,
                            ),
                            color: isExpired
                                ? Colors.white
                                : fadeColor(
                                    accent,
                                    widget.voucher.used ? 0.08 : 0.15,
                                  ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              widget.voucher.used
                                  ? Icons.check_rounded
                                  : Icons.circle_outlined,
                              key: ValueKey(widget.voucher.used),
                              size: 18,
                              color: widget.voucher.used
                                  ? AppColors.success
                                  : accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE7E9F2)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: fadeColor(AppColors.textPrimary, 0.08),
                  ),
                  color: fadeColor(AppColors.textPrimary, 0.04),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _copyToClipboard(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voucher code',
                              style: TextStyle(
                                color: mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.voucher.code,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _copyToClipboard(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: fadeColor(AppColors.primary, 0.12),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    isExpired ? Icons.error_outline : Icons.schedule,
                    size: 16,
                    color: isExpired ? AppColors.danger : mutedText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    expiryLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isExpired ? AppColors.danger : mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoucherStatusChip extends StatelessWidget {
  const _VoucherStatusChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fadeColor(foreground, 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_rounded, size: 48, color: AppColors.info),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: fadeColor(AppColors.textPrimary, 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class PendingRequestCard extends StatefulWidget {
  const PendingRequestCard({
    super.key,
    required this.request,
    required this.caseId,
    required this.hasResponse,
  });

  final InfoRequestItem request;
  final String caseId;
  final bool hasResponse;

  @override
  State<PendingRequestCard> createState() => _PendingRequestCardState();
}

class _PendingRequestCardState extends State<PendingRequestCard> {
  final _controller = TextEditingController();
  Uint8List? _attachmentBytes;
  bool _submitting = false;
  bool _showForm = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        // 10 MB limit
        if (bytes.length > 10 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.imageSizeMessage)),
          );
          return;
        }
        if (widget.request.requiresFile) {
          _submitFile(bytes);
        } else {
          setState(() => _attachmentBytes = bytes);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.filePickFailed(e.toString()))),
      );
    }
  }

  Future<void> _submit() async {
    final answer = _controller.text.trim();
    if (answer.isEmpty && _attachmentBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.answerOrFileRequired)),
      );
      return;
    }
    if (widget.request.requiresFile && _attachmentBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.fileRequired)));
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.read<AppState>().respondToAdditionalInfoServer(
        widget.caseId,
        requestId: widget.request.id,
        response: answer.isNotEmpty ? answer : 'File attached',
        attachment: _attachmentBytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.infoReceived)));
      setState(() {
        _showForm = false;
        _controller.clear();
        _attachmentBytes = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.submitFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _answer(String answer) async {
    setState(() => _submitting = true);
    try {
      await context.read<AppState>().respondToAdditionalInfoServer(
        widget.caseId,
        requestId: widget.request.id,
        response: answer,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.infoReceived)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.submitFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitFile(Uint8List attachment) async {
    setState(() => _submitting = true);
    try {
      await context.read<AppState>().respondToAdditionalInfoServer(
        widget.caseId,
        requestId: widget.request.id,
        response: 'File attached',
        attachment: attachment,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.fileReceived)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.fileSubmitFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawMessage = widget.request.message.trim();
    final message = CaseStatus.needsInfo.localizedNote(
      context.l10n,
      rawMessage,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.hasResponse
            ? fadeColor(Colors.green, 0.12)
            : fadeColor(AppColors.warning, 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                widget.hasResponse
                    ? Icons.check_circle_outline_rounded
                    : Icons.chat_bubble_outline_rounded,
                color: widget.hasResponse ? Colors.green : AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.requestedOn(widget.request.requestedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: fadeColor(AppColors.textPrimary, 0.6),
                      ),
                    ),
                    if (widget.request.requiresFile)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 16,
                              color: fadeColor(AppColors.textPrimary, 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.fileUploadRequired,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: fadeColor(
                                      AppColors.textPrimary,
                                      0.6,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.hasResponse)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '✓ ${context.l10n.responseSubmitted}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (!widget.hasResponse) ...[
            const SizedBox(height: 16),
            if (widget.request.requiresYesNo)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _answer('Yes'),
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.yes),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _answer('No'),
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.no),
                    ),
                  ),
                ],
              )
            else if (widget.request.requiresFile)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _submitting ? null : _pickAttachment,
                  icon: const Icon(Icons.attach_file),
                  label: Text(context.l10n.attachFile),
                ),
              )
            else if (!_showForm)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showForm = true),
                  child: Text(context.l10n.respond),
                ),
              )
            else ...[
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: context.l10n.answerHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.submit),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() {
                        _showForm = false;
                        _controller.clear();
                        _attachmentBytes = null;
                      }),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import 'package:claimy/core/theme/app_colors.dart';
import 'package:claimy/core/utils/formatters.dart';
import 'package:claimy/core/utils/string_utils.dart';
import 'package:claimy/features/new_case/new_case_screen.dart';
import 'package:claimy/state/app_state.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

enum _MainMenuAction { defaultCases, defaultRewards, signOut }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claim submitted. We\'ll keep you posted!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final bool showRewards = _currentView == HomeLanding.rewards;
    final unread = appState.cases.where((c) => c.hasUnreadUpdates).length;
    final firstName = appState.greetingName;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewCase,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New claim'),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                unreadCount > 0
                                    ? 'You have $unreadCount case updates waiting.'
                                    : 'All caught up! No new updates.',
                              ),
                            ),
                          );
                        },
                        onMenuSelected: (action) {
                          switch (action) {
                            case _MainMenuAction.defaultCases:
                              context.read<AppState>().setLandingPreference(
                                HomeLanding.cases,
                              );
                              setState(() => _currentView = HomeLanding.cases);
                              break;
                            case _MainMenuAction.defaultRewards:
                              context.read<AppState>().setLandingPreference(
                                HomeLanding.rewards,
                              );
                              setState(
                                () => _currentView = HomeLanding.rewards,
                              );
                              break;
                            case _MainMenuAction.signOut:
                              context.read<AppState>().signOut();
                              break;
                          }
                        },
                        showRewards: showRewards,
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.firstName,
    required this.currentView,
    required this.unreadCount,
    required this.onViewChanged,
    required this.onNotificationsTap,
    required this.onMenuSelected,
    required this.showRewards,
  });

  final String firstName;
  final HomeLanding currentView;
  final int unreadCount;
  final ValueChanged<HomeLanding> onViewChanged;
  final VoidCallback onNotificationsTap;
  final ValueChanged<_MainMenuAction> onMenuSelected;
  final bool showRewards;

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
                    'Hey, $firstName',
                    style: textTheme.titleMedium?.copyWith(
                      color: fadeColor(AppColors.textPrimary, 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    showRewards ? 'Rewards hub' : 'Claim overview',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
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
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _MainMenuAction.defaultCases,
                  child: Text('Make My Cases default'),
                ),
                PopupMenuItem(
                  value: _MainMenuAction.defaultRewards,
                  child: Text('Make My Rewards default'),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: _MainMenuAction.signOut,
                  child: Text('Sign out'),
                ),
              ],
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
            label: 'My cases',
            selected: currentView == HomeLanding.cases,
            onTap: () => onViewChanged(HomeLanding.cases),
            textTheme: textTheme,
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: 'My rewards',
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
    final cases = context.watch<AppState>().cases;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search store or product',
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
        SizedBox(
          height: 46,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _statusFilter == null,
                onSelected: (_) => setState(() => _statusFilter = null),
              ),
              const SizedBox(width: 8),
              ...CaseStatus.values.map(
                (status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status.label),
                    selectedColor: status.backgroundColor,
                    selected: _statusFilter == status,
                    onSelected: (_) => setState(() => _statusFilter = status),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filtered.isEmpty
              ? const _EmptyState(
                  title: 'No cases found',
                  subtitle:
                      'Try adjusting your filters or creating a new claim.',
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

class RewardsView extends StatelessWidget {
  const RewardsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vouchers = context.watch<AppState>().vouchers;

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
                    'Use your vouchers instantly while shopping in-store or online.',
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
        Expanded(
          child: vouchers.isEmpty
              ? const _EmptyState(
                  title: 'No active rewards yet',
                  subtitle:
                      'Submit claims to unlock vouchers and cashback offers.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: vouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = vouchers[index];
                    return VoucherCard(voucher: voucher);
                  },
                ),
        ),
      ],
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
          boxShadow: [
            BoxShadow(
              color: fadeColor(Colors.black, highlight ? 0.12 : 0.05),
              blurRadius: highlight ? 18 : 10,
              offset: const Offset(0, 8),
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
                  'Updated ${formatRelativeTime(caseModel.lastUpdated)}',
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
                      children: const [
                        Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'New update',
                          style: TextStyle(
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
                        'We need one quick detail from you.',
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
            status.label,
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
    context.read<AppState>().respondToAdditionalInfo(widget.caseId, response);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Thanks! We noted "$response".')));
  }

  @override
  Widget build(BuildContext context) {
    final caseModel = context.select<AppState, CaseModel?>(
      (state) => state.caseById(widget.caseId),
    );

    if (caseModel == null) {
      return const Scaffold(body: Center(child: Text('Case not found')));
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
                              'Created ${formatMediumDate(caseModel.createdAt)}',
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
                            'Last update ${formatRelativeTime(caseModel.lastUpdated)}',
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
          if (caseModel.requiresAdditionalInfo)
            AdditionalInfoCard(
              question: caseModel.pendingQuestion!,
              onAnswer: _answerQuestion,
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status history',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  context.read<AppState>().simulateProgress(widget.caseId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Simulated an update. Check the timeline!'),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Simulate update'),
              ),
            ],
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
                        children: const [
                          Text(
                            'Receipt image',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Open or copy the receipt image link if needed.',
                            style: TextStyle(color: Colors.black54),
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
                                SnackBar(content: Text('Could not open: $url')),
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Open'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final url = caseModel.receiptImageUrl!;
                            await Clipboard.setData(ClipboardData(text: url));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Receipt link copied to clipboard',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy'),
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
                    entry.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${entry.isCustomerAction ? 'You' : 'Support'} • ${formatMediumDate(entry.timestamp)}',
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

class AdditionalInfoCard extends StatelessWidget {
  const AdditionalInfoCard({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  final String question;
  final void Function(String response) onAnswer;

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
                  question,
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
                onPressed: () => onAnswer('Yes'),
                child: const Text('Yes'),
              ),
              ElevatedButton(
                onPressed: () => onAnswer('No'),
                child: const Text('No'),
              ),
              OutlinedButton.icon(
                onPressed: () => onAnswer('Uploaded photo'),
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Upload photo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VoucherCard extends StatelessWidget {
  const VoucherCard({super.key, required this.voucher});

  final Voucher voucher;

  @override
  Widget build(BuildContext context) {
    final expiresIn = voucher.expiration.difference(DateTime.now()).inDays;
    final appState = context.read<AppState>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: fadeColor(AppColors.accent, 0.12),
                  child: Text(
                    toInitial(voucher.storeName),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.storeName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voucher.amountLabel,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: voucher.used,
                  onChanged: (_) {
                    appState.toggleVoucherUsed(voucher.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: fadeColor(AppColors.textPrimary, 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  expiresIn >= 0
                      ? 'Expires in $expiresIn day${expiresIn == 1 ? '' : 's'}'
                      : 'Expired',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: fadeColor(AppColors.textPrimary, 0.6),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    voucher.code,
                    style: const TextStyle(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(showRewards ? 'My rewards' : 'My cases'),
        actions: [
          IconButton(
            onPressed: () {
              final unread = appState.cases
                  .where((c) => c.hasUnreadUpdates)
                  .length;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    unread > 0
                        ? 'You have $unread case updates waiting.'
                        : 'All caught up! No new updates.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          PopupMenuButton<_MainMenuAction>(
            onSelected: (action) {
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
                  setState(() => _currentView = HomeLanding.rewards);
                  break;
                case _MainMenuAction.signOut:
                  context.read<AppState>().signOut();
                  break;
              }
            },
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
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: fadeColor(Colors.black, 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ToggleButtons(
                isSelected: [
                  _currentView == HomeLanding.cases,
                  _currentView == HomeLanding.rewards,
                ],
                onPressed: (index) {
                  setState(
                    () => _currentView = index == 0
                        ? HomeLanding.cases
                        : HomeLanding.rewards,
                  );
                },
                borderRadius: BorderRadius.circular(24),
                fillColor: fadeColor(AppColors.primary, 0.12),
                renderBorder: false,
                constraints: const BoxConstraints(minHeight: 48, minWidth: 120),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('My cases'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('My rewards'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: showRewards
            ? const RewardsView(key: ValueKey('rewards'))
            : const CasesView(key: ValueKey('cases')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewCase,
        child: const Icon(Icons.add_rounded),
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
                CircleAvatar(
                  backgroundColor: fadeColor(AppColors.primary, 0.1),
                  child: Text(
                    toInitial(caseModel.storeName),
                    style: const TextStyle(
                      color: AppColors.primary,
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
                      CircleAvatar(
                        backgroundColor: fadeColor(AppColors.primary, 0.1),
                        child: Text(
                          toInitial(caseModel.storeName),
                          style: const TextStyle(
                            color: AppColors.primary,
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

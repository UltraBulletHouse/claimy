import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const ClaimyApp()),
  );
}

class ClaimyApp extends StatelessWidget {
  const ClaimyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Claimy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          secondary: AppColors.accent,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFFE8EEFF),
          labelStyle: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          shape: StadiumBorder(),
        ),
      ),
      home: const AppEntryPoint(),
    );
  }
}

class AppColors {
  static const Color primary = Color(0xFF3568FF);
  static const Color accent = Color(0xFFFF7A59);
  static const Color surface = Color(0xFFF5F7FB);
  static const Color textPrimary = Color(0xFF1F2430);
  static const Color success = Color(0xFF3CC48D);
  static const Color warning = Color(0xFFFFB34D);
  static const Color info = Color(0xFF566CFF);
  static const Color danger = Color(0xFFE57373);
}

class AppEntryPoint extends StatelessWidget {
  const AppEntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return appState.isAuthenticated
            ? const HomeShell()
            : const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AppState>().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 64,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your product claims and rewards in minutes.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary.fade(0.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter an email';
                                }
                                if (!value.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Use at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Forgot password?'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _submit,
                              child: const Text('Log in'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: const Text('Create an account'),
                      ),
                      const Spacer(),
                      Text(
                        'By continuing you agree to Claimy\'s Terms and Privacy Policy.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.fade(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AppState>().register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Let’s get you started',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter an email';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    helperText: 'Use at least 8 characters',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Create a password';
                    }
                    if (value.length < 8) {
                      return 'Use at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Sign up'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Already have an account?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.fade(0.7),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email to continue')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Check $email for a link to reset your password.'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'We\'ll email you a reset link.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Send reset link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                    color: Colors.black.fade(0.05),
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
                fillColor: AppColors.primary.fade(0.12),
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
              ? _EmptyState(
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
                  color: Colors.black.fade(0.05),
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
                      color: AppColors.textPrimary.fade(0.7),
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
              color: Colors.black.fade(highlight ? 0.12 : 0.05),
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
                  backgroundColor: AppColors.primary.fade(0.1),
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
                          color: AppColors.textPrimary.fade(0.6),
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
                  color: AppColors.textPrimary.fade(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Updated ${formatRelativeTime(caseModel.lastUpdated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.fade(0.6),
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
                      color: AppColors.accent.fade(0.12),
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
                  color: AppColors.warning.fade(0.12),
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
                          color: AppColors.warning.darker(),
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
                        backgroundColor: AppColors.primary.fade(0.1),
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
                                    color: AppColors.textPrimary.fade(0.6),
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
                                  color: AppColors.textPrimary.fade(0.7),
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
                  color: AppColors.surface.darker(0.1),
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
                    color: Colors.black.fade(0.04),
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
                      color: AppColors.textPrimary.fade(0.6),
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
        color: AppColors.warning.fade(0.12),
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
                  backgroundColor: AppColors.accent.fade(0.12),
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
                  color: AppColors.textPrimary.fade(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  expiresIn >= 0
                      ? 'Expires in $expiresIn day${expiresIn == 1 ? '' : 's'}'
                      : 'Expired',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.fade(0.6),
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

class NewCaseScreen extends StatefulWidget {
  const NewCaseScreen({super.key});

  @override
  State<NewCaseScreen> createState() => _NewCaseScreenState();
}

class _NewCaseScreenState extends State<NewCaseScreen> {
  static const int _stepsCount = 4;
  final List<String> _stores = const [
    'FreshMart Market',
    'TechTown',
    'HomeGoods Depot',
    'Daily Grains',
    'Beauty Loft',
  ];

  int _currentStep = 0;
  String? _selectedStore;
  bool _customStore = false;
  final TextEditingController _customStoreController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _productPhotoAdded = false;
  bool _receiptPhotoAdded = false;

  @override
  void dispose() {
    _customStoreController.dispose();
    _productController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_validateCurrentStep()) {
      FocusScope.of(context).unfocus();
      setState(() => _currentStep++);
    }
  }

  void _goBack() {
    setState(() => _currentStep--);
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if ((_selectedStore == null || _selectedStore!.isEmpty) &&
            _customStoreController.text.trim().isEmpty) {
          _showMessage('Select a store to continue.');
          return false;
        }
        return true;
      case 1:
        if (_productController.text.trim().isEmpty) {
          _showMessage('Tell us the product name.');
          return false;
        }
        return true;
      case 2:
        if (!_productPhotoAdded || !_receiptPhotoAdded) {
          _showMessage('Please add both photos before continuing.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handlePrimaryAction() {
    if (_currentStep == _stepsCount - 1) {
      _submit();
    } else {
      _goNext();
    }
  }

  void _submit() {
    if (!_validateCurrentStep()) {
      return;
    }
    final store = _customStore
        ? _customStoreController.text.trim()
        : _selectedStore!;
    final product = _productController.text.trim();
    final description = _descriptionController.text.trim();
    context.read<AppState>().createCase(
      storeName: store,
      productName: product,
      description: description,
      includedProductPhoto: _productPhotoAdded,
      includedReceiptPhoto: _receiptPhotoAdded,
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New claim')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepIndicator(
                currentStep: _currentStep,
                totalSteps: _stepsCount,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildStepContent(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ).copyWith(bottom: 16),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goBack,
                    child: const Text('Back'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                flex: _currentStep > 0 ? 2 : 1,
                child: ElevatedButton(
                  onPressed: _handlePrimaryAction,
                  child: Text(
                    _currentStep == _stepsCount - 1
                        ? 'Submit claim'
                        : 'Continue',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _StoreStep(
          stores: _stores,
          selectedStore: _selectedStore,
          customStore: _customStore,
          customStoreController: _customStoreController,
          onStoreChanged: (value) {
            setState(() {
              if (value == '_custom_') {
                _selectedStore = null;
                _customStore = true;
              } else {
                _selectedStore = value;
                _customStore = false;
              }
            });
          },
        );
      case 1:
        return _ProductStep(controller: _productController);
      case 2:
        return _PhotosStep(
          productPhotoAdded: _productPhotoAdded,
          receiptPhotoAdded: _receiptPhotoAdded,
          onToggleProduct: () {
            setState(() => _productPhotoAdded = !_productPhotoAdded);
          },
          onToggleReceipt: () {
            setState(() => _receiptPhotoAdded = !_receiptPhotoAdded);
          },
        );
      case 3:
        return _NotesStep(controller: _descriptionController);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StoreStep extends StatelessWidget {
  const _StoreStep({
    required this.stores,
    required this.selectedStore,
    required this.customStore,
    required this.customStoreController,
    required this.onStoreChanged,
  });

  final List<String> stores;
  final String? selectedStore;
  final bool customStore;
  final TextEditingController customStoreController;
  final ValueChanged<String> onStoreChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where did you buy it?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose the store so we can route your claim to the right team.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary.fade(0.7),
          ),
        ),
        const SizedBox(height: 24),
        DropdownMenu<String>(
          initialSelection: customStore ? '_custom_' : selectedStore,
          expandedInsets: EdgeInsets.zero,
          label: const Text('Store'),
          dropdownMenuEntries: [
            ...stores.map(
              (store) => DropdownMenuEntry<String>(value: store, label: store),
            ),
            const DropdownMenuEntry<String>(
              value: '_custom_',
              label: 'Other store',
            ),
          ],
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          onSelected: (value) {
            if (value != null) {
              onStoreChanged(value);
            }
          },
        ),
        if (customStore) ...[
          const SizedBox(height: 16),
          TextField(
            controller: customStoreController,
            decoration: const InputDecoration(
              labelText: 'Store name',
              hintText: 'Type the store name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductStep extends StatelessWidget {
  const _ProductStep({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s the product?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Be specific so the store can identify it quickly.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary.fade(0.7),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Product name',
            hintText: 'e.g. Organic almond milk 1L',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotosStep extends StatelessWidget {
  const _PhotosStep({
    required this.productPhotoAdded,
    required this.receiptPhotoAdded,
    required this.onToggleProduct,
    required this.onToggleReceipt,
  });

  final bool productPhotoAdded;
  final bool receiptPhotoAdded;
  final VoidCallback onToggleProduct;
  final VoidCallback onToggleReceipt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add your photos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Upload a product photo and the receipt so we can verify your claim.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary.fade(0.7),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _PhotoBox(
                label: 'Product photo',
                added: productPhotoAdded,
                onTap: onToggleProduct,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _PhotoBox(
                label: 'Receipt photo',
                added: receiptPhotoAdded,
                onTap: onToggleReceipt,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({
    required this.label,
    required this.added,
    required this.onTap,
  });

  final String label;
  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              added
                  ? 'Removed $label placeholder.'
                  : 'Pretending to add $label.',
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 150,
        decoration: BoxDecoration(
          color: added ? AppColors.success.fade(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: added ? AppColors.success : AppColors.textPrimary.fade(0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              added ? Icons.check_circle_rounded : Icons.add_a_photo_rounded,
              color: added ? AppColors.success : AppColors.textPrimary,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              added ? 'Photo added' : 'Tap to add',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.fade(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesStep extends StatelessWidget {
  const _NotesStep({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anything else?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Let us know what happened. Keep it short and friendly.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary.fade(0.7),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Optional note',
            hintText: 'Tell us what went wrong so we can fix it.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
            height: 10,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : AppColors.surface.darker(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }),
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
                color: AppColors.textPrimary.fade(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum CaseStatus { pending, inReview, needsInfo, approved, rejected }

extension CaseStatusX on CaseStatus {
  String get label {
    switch (this) {
      case CaseStatus.pending:
        return 'Pending';
      case CaseStatus.inReview:
        return 'In review';
      case CaseStatus.needsInfo:
        return 'Need info';
      case CaseStatus.approved:
        return 'Approved';
      case CaseStatus.rejected:
        return 'Declined';
    }
  }

  Color get color {
    switch (this) {
      case CaseStatus.pending:
        return AppColors.info;
      case CaseStatus.inReview:
        return const Color(0xFF7A6CFF);
      case CaseStatus.needsInfo:
        return AppColors.warning;
      case CaseStatus.approved:
        return AppColors.success;
      case CaseStatus.rejected:
        return AppColors.danger;
    }
  }

  Color get backgroundColor => color.fade(0.12);

  IconData get icon {
    switch (this) {
      case CaseStatus.pending:
        return Icons.schedule_rounded;
      case CaseStatus.inReview:
        return Icons.loop_rounded;
      case CaseStatus.needsInfo:
        return Icons.help_outline_rounded;
      case CaseStatus.approved:
        return Icons.verified_rounded;
      case CaseStatus.rejected:
        return Icons.highlight_off_rounded;
    }
  }
}

enum HomeLanding { cases, rewards }

class CaseUpdate {
  CaseUpdate({
    required this.status,
    required this.message,
    required this.timestamp,
    this.isCustomerAction = false,
  });

  final CaseStatus status;
  final String message;
  final DateTime timestamp;
  final bool isCustomerAction;
}

class CaseModel {
  CaseModel({
    required this.id,
    required this.storeName,
    required this.productName,
    required this.createdAt,
    required this.status,
    required List<CaseUpdate> history,
    this.hasUnreadUpdates = false,
    this.pendingQuestion,
  }) : history = List<CaseUpdate>.from(history);

  final String id;
  final String storeName;
  final String productName;
  final DateTime createdAt;
  CaseStatus status;
  final List<CaseUpdate> history;
  bool hasUnreadUpdates;
  String? pendingQuestion;

  DateTime get lastUpdated =>
      history.isNotEmpty ? history.last.timestamp : createdAt;

  bool get requiresAdditionalInfo => pendingQuestion != null;
}

class Voucher {
  Voucher({
    required this.id,
    required this.storeName,
    required this.amountLabel,
    required this.code,
    required this.expiration,
    this.used = false,
  });

  final String id;
  final String storeName;
  final String amountLabel;
  final String code;
  final DateTime expiration;
  bool used;
}

class AppState extends ChangeNotifier {
  AppState() {
    _seedDemoData();
  }

  final List<CaseModel> _cases = [];
  final List<Voucher> _vouchers = [];
  bool _isAuthenticated = false;
  HomeLanding _landingPreference = HomeLanding.cases;

  bool get isAuthenticated => _isAuthenticated;
  HomeLanding get landingPreference => _landingPreference;

  List<CaseModel> get cases {
    final sorted = [..._cases];
    sorted.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    return List.unmodifiable(sorted);
  }

  List<Voucher> get vouchers {
    final sorted = [..._vouchers];
    sorted.sort(
      (a, b) => a.used == b.used
          ? a.expiration.compareTo(b.expiration)
          : (a.used ? 1 : -1),
    );
    return List.unmodifiable(sorted);
  }

  void signIn({required String email, required String password}) {
    _isAuthenticated = true;
    notifyListeners();
  }

  void register({
    required String name,
    required String email,
    required String password,
  }) {
    _isAuthenticated = true;
    notifyListeners();
  }

  void signOut() {
    _isAuthenticated = false;
    notifyListeners();
  }

  void setLandingPreference(HomeLanding view) {
    if (_landingPreference != view) {
      _landingPreference = view;
      notifyListeners();
    }
  }

  CaseModel? caseById(String id) {
    try {
      return _cases.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void markCaseUpdatesRead(String id) {
    final caseModel = caseById(id);
    if (caseModel != null && caseModel.hasUnreadUpdates) {
      caseModel.hasUnreadUpdates = false;
      notifyListeners();
    }
  }

  void respondToAdditionalInfo(String id, String response) {
    final caseModel = caseById(id);
    if (caseModel == null) return;
    caseModel.pendingQuestion = null;
    caseModel.status = CaseStatus.inReview;
    caseModel.history.add(
      CaseUpdate(
        status: CaseStatus.inReview,
        message: 'You responded: $response',
        timestamp: DateTime.now(),
        isCustomerAction: true,
      ),
    );
    caseModel.hasUnreadUpdates = false;
    notifyListeners();
  }

  void createCase({
    required String storeName,
    required String productName,
    required String description,
    required bool includedProductPhoto,
    required bool includedReceiptPhoto,
  }) {
    final now = DateTime.now();
    final newCase = CaseModel(
      id: 'case-${now.millisecondsSinceEpoch}',
      storeName: storeName,
      productName: productName,
      createdAt: now,
      status: CaseStatus.pending,
      history: [
        CaseUpdate(
          status: CaseStatus.pending,
          message:
              'You submitted the claim with product and receipt photos attached.',
          timestamp: now,
          isCustomerAction: true,
        ),
        if (description.isNotEmpty)
          CaseUpdate(
            status: CaseStatus.pending,
            message: 'Additional note: $description',
            timestamp: now.add(const Duration(minutes: 1)),
            isCustomerAction: true,
          ),
      ],
      hasUnreadUpdates: false,
    );
    _cases.add(newCase);
    notifyListeners();
  }

  void toggleVoucherUsed(String id) {
    final voucher = _vouchers.firstWhere(
      (v) => v.id == id,
      orElse: () => throw ArgumentError('Voucher not found'),
    );
    voucher.used = !voucher.used;
    notifyListeners();
  }

  void simulateProgress(String id) {
    final caseModel = caseById(id);
    if (caseModel == null) return;
    final now = DateTime.now();
    CaseStatus nextStatus;
    String message;
    switch (caseModel.status) {
      case CaseStatus.pending:
        nextStatus = CaseStatus.inReview;
        message = 'A specialist started reviewing your claim.';
        break;
      case CaseStatus.inReview:
        nextStatus = CaseStatus.needsInfo;
        message = 'We need the purchase date from your receipt.';
        caseModel.pendingQuestion =
            'Could you confirm the purchase date on your receipt?';
        break;
      case CaseStatus.needsInfo:
        nextStatus = CaseStatus.approved;
        message =
            'Great news! Your claim was approved. A reward voucher is ready.';
        caseModel.pendingQuestion = null;
        _grantVoucherForCase(caseModel);
        break;
      case CaseStatus.approved:
        nextStatus = CaseStatus.rejected;
        message = 'The case was closed.';
        break;
      case CaseStatus.rejected:
        nextStatus = CaseStatus.pending;
        message = 'Case reopened for review.';
        break;
    }
    caseModel.status = nextStatus;
    caseModel.history.add(
      CaseUpdate(
        status: nextStatus,
        message: message,
        timestamp: now,
        isCustomerAction: false,
      ),
    );
    caseModel.hasUnreadUpdates = true;
    notifyListeners();
  }

  void _grantVoucherForCase(CaseModel caseModel) {
    final random = Random();
    final code = 'THANKS${random.nextInt(9999).toString().padLeft(4, '0')}';
    final voucher = Voucher(
      id: 'voucher-${DateTime.now().millisecondsSinceEpoch}',
      storeName: caseModel.storeName,
      amountLabel: '15% off your next purchase',
      code: code,
      expiration: DateTime.now().add(const Duration(days: 60)),
      used: false,
    );
    _vouchers.add(voucher);
  }

  void _seedDemoData() {
    final now = DateTime.now();
    _cases.addAll([
      CaseModel(
        id: 'case-1001',
        storeName: 'FreshMart Market',
        productName: 'Organic almond milk',
        createdAt: now.subtract(const Duration(days: 6)),
        status: CaseStatus.needsInfo,
        hasUnreadUpdates: true,
        pendingQuestion: 'Do you still have the original packaging?',
        history: [
          CaseUpdate(
            status: CaseStatus.pending,
            message: 'You submitted the claim.',
            timestamp: now.subtract(const Duration(days: 6)),
            isCustomerAction: true,
          ),
          CaseUpdate(
            status: CaseStatus.inReview,
            message: 'A specialist picked up your claim.',
            timestamp: now.subtract(const Duration(days: 5, hours: 6)),
          ),
          CaseUpdate(
            status: CaseStatus.needsInfo,
            message:
                'We need a quick photo of the packaging to keep things moving.',
            timestamp: now.subtract(const Duration(hours: 5)),
          ),
        ],
      ),
      CaseModel(
        id: 'case-1002',
        storeName: 'TechTown',
        productName: 'Bluetooth earbuds (Graphite)',
        createdAt: now.subtract(const Duration(days: 3)),
        status: CaseStatus.inReview,
        history: [
          CaseUpdate(
            status: CaseStatus.pending,
            message: 'You submitted the claim.',
            timestamp: now.subtract(const Duration(days: 3)),
            isCustomerAction: true,
          ),
          CaseUpdate(
            status: CaseStatus.inReview,
            message: 'We are talking to the store about a replacement.',
            timestamp: now.subtract(const Duration(days: 1, hours: 12)),
          ),
        ],
      ),
      CaseModel(
        id: 'case-1003',
        storeName: 'Beauty Loft',
        productName: 'Vitamin C serum',
        createdAt: now.subtract(const Duration(days: 12)),
        status: CaseStatus.approved,
        history: [
          CaseUpdate(
            status: CaseStatus.pending,
            message: 'You submitted the claim.',
            timestamp: now.subtract(const Duration(days: 12)),
            isCustomerAction: true,
          ),
          CaseUpdate(
            status: CaseStatus.inReview,
            message: 'We are validating the issue with Beauty Loft.',
            timestamp: now.subtract(const Duration(days: 10)),
          ),
          CaseUpdate(
            status: CaseStatus.approved,
            message:
                'Approved! We issued a 10% discount voucher for your next purchase.',
            timestamp: now.subtract(const Duration(days: 2)),
          ),
        ],
      ),
    ]);

    _vouchers.addAll([
      Voucher(
        id: 'voucher-01',
        storeName: 'Beauty Loft',
        amountLabel: '10% off skin care',
        code: 'GLOW10',
        expiration: now.add(const Duration(days: 18)),
      ),
      Voucher(
        id: 'voucher-02',
        storeName: 'HomeGoods Depot',
        amountLabel: '\$15 cashback certificate',
        code: 'HGDSAVE15',
        expiration: now.add(const Duration(days: 45)),
      ),
    ]);
  }
}

String formatRelativeTime(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return formatMediumDate(dateTime);
}

String formatMediumDate(DateTime dateTime) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[dateTime.month - 1];
  return '$month ${dateTime.day}, ${dateTime.year}';
}

String toInitial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed[0].toUpperCase();
}

extension _ColorHelpers on Color {
  Color fade(double alpha) => withValues(alpha: alpha);

  Color darker([double amount = 0.2]) {
    final hsl = HSLColor.fromColor(this);
    final adjusted = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return adjusted.toColor();
  }
}

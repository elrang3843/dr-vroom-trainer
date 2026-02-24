/// Dashboard Screen — Main screen for Dr. Vroom Trainer App
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trainer_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../label/label_screen.dart';
import '../review/review_screen.dart';
import '../upload/upload_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    LabelScreen(),
    ReviewScreen(),
    UploadScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final trainer = context.read<TrainerProvider>();
      trainer.updateFromAuth(auth.serverUrl, auth.token);
      trainer.loadKnowledgeStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.label), label: '레이블'),
          BottomNavigationBarItem(icon: Icon(Icons.rate_review), label: '검토'),
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: '업로드'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}

// ─── Home Tab ────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final trainer = context.watch<TrainerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('닥터브릉이 교육'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              trainer.updateFromAuth(auth.serverUrl, auth.token);
              trainer.loadKnowledgeStats();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          trainer.updateFromAuth(auth.serverUrl, auth.token);
          await trainer.loadKnowledgeStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              _WelcomeCard(username: auth.username ?? '트레이너', role: auth.role),
              const SizedBox(height: 16),

              // Stats grid
              if (trainer.stats != null) ...[
                _StatsGrid(stats: trainer.stats!),
                const SizedBox(height: 16),
                _ComponentBreakdown(stats: trainer.stats!),
              ] else if (trainer.isLoading)
                const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF00C896)))
              else
                _NoServerCard(
                  onRetry: () {
                    trainer.updateFromAuth(auth.serverUrl, auth.token);
                    trainer.loadKnowledgeStats();
                  },
                ),

              const SizedBox(height: 16),

              // Quick actions
              const Text(
                '빠른 작업',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _QuickActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String username;
  final String role;
  const _WelcomeCard({required this.username, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C896), Color(0xFF0088FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Icon(
              role == 'expert' ? Icons.verified : Icons.school,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '안녕하세요, $username님!',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                role == 'expert' ? '전문가 계정' : '트레이너 계정',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.white70),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final KnowledgeStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          label: '총 지식',
          value: '${stats.totalKnowledge}',
          icon: Icons.psychology,
          color: const Color(0xFF00C896),
        ),
        _StatCard(
          label: '전문가 확인',
          value: '${stats.confirmedByExpert}',
          icon: Icons.verified,
          color: const Color(0xFF0088FF),
        ),
        _StatCard(
          label: '평균 신뢰도',
          value: '${(stats.avgConfidence * 100).toStringAsFixed(0)}%',
          icon: Icons.bar_chart,
          color: const Color(0xFFFFB800),
        ),
        _StatCard(
          label: '진단 세션',
          value: '${stats.totalDiagnosticSessions}',
          icon: Icons.history,
          color: const Color(0xFFFF6B35),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ComponentBreakdown extends StatelessWidget {
  final KnowledgeStats stats;
  const _ComponentBreakdown({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '부품별 지식량',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...AppConstants.components.map((comp) {
            final count = stats.byComponent[comp] ?? 0;
            final total = stats.totalKnowledge > 0
                ? stats.totalKnowledge
                : 1;
            final percent = count / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      AppConstants.componentNames[comp]!.split(' ').first,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 8,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.componentColor(comp)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: TextStyle(
                        color: AppTheme.componentColor(comp),
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.label,
            label: '레이블링',
            subtitle: '새 데이터 교육',
            color: const Color(0xFF00C896),
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.rate_review,
            label: '지식 검토',
            subtitle: '저장된 지식 확인',
            color: const Color(0xFF0088FF),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            Text(
              subtitle,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoServerCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _NoServerCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
          const SizedBox(height: 12),
          const Text(
            '서버에 연결할 수 없습니다',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          const Text(
            '설정에서 서버 URL을 확인하세요',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

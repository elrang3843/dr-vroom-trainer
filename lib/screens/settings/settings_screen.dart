/// Settings Screen for Dr. Vroom Trainer App
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trainer_provider.dart';
import '../../core/constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverUrlCtrl = TextEditingController();
  bool _serverConnected = false;
  bool _checkingConnection = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      _serverUrlCtrl.text = auth.serverUrl;
      _checkConnection();
    });
  }

  @override
  void dispose() {
    _serverUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    setState(() => _checkingConnection = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.checkServerConnection();
    setState(() {
      _serverConnected = ok;
      _checkingConnection = false;
    });
  }

  Future<void> _saveServerUrl() async {
    final auth = context.read<AuthProvider>();
    await auth.updateServerUrl(_serverUrlCtrl.text.trim());
    final trainer = context.read<TrainerProvider>();
    trainer.updateFromAuth(auth.serverUrl, auth.token);
    await _checkConnection();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_serverConnected ? '서버 연결 성공!' : '서버에 연결할 수 없습니다.'),
        backgroundColor:
            _serverConnected ? const Color(0xFF00C896) : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            _SectionTitle('프로필'),
            _ProfileCard(
              username: auth.username ?? '알 수 없음',
              role: auth.role,
            ),
            const SizedBox(height: 24),

            // Server config
            _SectionTitle('서버 설정'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _serverConnected ? Icons.cloud_done : Icons.cloud_off,
                        color: _serverConnected
                            ? const Color(0xFF00C896)
                            : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _serverConnected ? '서버 연결됨' : '서버 연결 없음',
                        style: TextStyle(
                          color: _serverConnected
                              ? const Color(0xFF00C896)
                              : Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _serverUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: '서버 URL',
                      prefixIcon: Icon(Icons.cloud),
                      hintText: 'http://localhost:8000',
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _checkingConnection ? null : _saveServerUrl,
                          child: _checkingConnection
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 2))
                              : const Text('저장 및 연결 확인'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App info
            _SectionTitle('앱 정보'),
            _InfoCard(),
            const SizedBox(height: 24),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (!mounted) return;
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (r) => false);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('로그아웃',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String username;
  final String role;
  const _ProfileCard({required this.username, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF00C896).withValues(alpha: 0.2),
            child: Icon(
              role == 'expert' ? Icons.verified : Icons.school,
              color: const Color(0xFF00C896),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(username,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text(
                role == 'expert' ? '전문가 (Expert)' : '트레이너 (Trainer)',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _InfoRow('앱 이름', AppConstants.appName),
          _InfoRow('한국어 이름', AppConstants.appNameKr),
          _InfoRow('버전', AppConstants.version),
          _InfoRow('특허', AppConstants.patentNo),
          _InfoRow('역할', 'Trainer / Expert'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 12))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

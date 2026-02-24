/// Login / Register Screen for Dr. Vroom Trainer App
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _serverUrlCtrl = TextEditingController();

  bool _isRegisterMode = false;
  String _selectedRole = 'trainer';
  bool _obscurePassword = true;
  bool _serverConfigExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      _serverUrlCtrl.text = auth.serverUrl;
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
    _serverUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Update server URL if changed
    final auth = context.read<AuthProvider>();
    if (_serverUrlCtrl.text.trim() != auth.serverUrl) {
      await auth.updateServerUrl(_serverUrlCtrl.text.trim());
    }

    Map<String, dynamic> result;
    if (_isRegisterMode) {
      result = await auth.register(
        _usernameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        _selectedRole,
      );
    } else {
      result = await auth.login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );
    }

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? '오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Header
                const Icon(Icons.school, size: 64, color: Color(0xFF00C896)),
                const SizedBox(height: 16),
                const Text(
                  'DR. VROOM TRAINER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF00C896),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  '닥터브릉이 교육 플랫폼',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // Mode toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isRegisterMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isRegisterMode
                                ? const Color(0xFF00C896)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(12)),
                            border: Border.all(color: const Color(0xFF00C896)),
                          ),
                          child: Text(
                            '로그인',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isRegisterMode
                                  ? Colors.black
                                  : const Color(0xFF00C896),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isRegisterMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isRegisterMode
                                ? const Color(0xFF00C896)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(12)),
                            border: Border.all(color: const Color(0xFF00C896)),
                          ),
                          child: Text(
                            '회원가입',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isRegisterMode
                                  ? Colors.black
                                  : const Color(0xFF00C896),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Username field
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: '사용자명',
                    prefixIcon: Icon(Icons.person),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (v) =>
                      v?.isEmpty == true ? '사용자명을 입력하세요' : null,
                ),
                const SizedBox(height: 16),

                // Email (register only)
                if (_isRegisterMode) ...[
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      prefixIcon: Icon(Icons.email),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v?.isEmpty == true ? '이메일을 입력하세요' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Password field
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      color: Colors.white54,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (v) =>
                      (v?.length ?? 0) < 6 ? '비밀번호는 6자 이상이어야 합니다' : null,
                ),

                // Role selection (register only)
                if (_isRegisterMode) ...[
                  const SizedBox(height: 16),
                  const Text('역할 선택',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _roleChip('trainer', '트레이너'),
                      const SizedBox(width: 8),
                      _roleChip('expert', '전문가'),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Server config (collapsible)
                GestureDetector(
                  onTap: () => setState(
                      () => _serverConfigExpanded = !_serverConfigExpanded),
                  child: Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.white38, size: 16),
                      const SizedBox(width: 8),
                      const Text('서버 설정',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 13)),
                      const Spacer(),
                      Icon(
                        _serverConfigExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.white38,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                if (_serverConfigExpanded) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _serverUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: '서버 URL',
                      prefixIcon: Icon(Icons.cloud),
                      hintText: 'http://localhost:8000',
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 32),

                // Submit button
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isRegisterMode ? '회원가입' : '로그인',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 24),

                // Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C896).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF00C896).withValues(alpha: 0.2)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '역할 안내',
                        style: TextStyle(
                            color: Color(0xFF00C896),
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '• 트레이너: 진단 데이터 레이블링, 지식 교육\n'
                        '• 전문가: 지식 검증, 데이터 승인 및 삭제',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
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

  Widget _roleChip(String role, String label) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00C896).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00C896)
                : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00C896) : Colors.white54,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

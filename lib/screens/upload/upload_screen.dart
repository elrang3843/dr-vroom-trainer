/// Upload Screen — Upload demo/test audio patterns to server
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../providers/auth_provider.dart';
import '../../providers/trainer_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  // Demo fault patterns that trainers can upload
  final List<_DemoPattern> _patterns = [
    _DemoPattern(
      name: '엔진 노킹',
      nameEn: 'Engine Knock',
      component: 'engine',
      status: 'warning',
      faultCode: 'engine_knock',
      dominantFreq: 120.0,
      rms: 0.45,
      description: '엔진 노킹 현상. 연소 타이밍 불량으로 발생하는 충격음.',
      color: const Color(0xFFFF6B35),
    ),
    _DemoPattern(
      name: '베어링 외륜 손상',
      nameEn: 'Bearing Outer Race',
      component: 'bearing',
      status: 'critical',
      faultCode: 'bearing_outer_race',
      dominantFreq: 1800.0,
      rms: 0.62,
      description: '휠 베어링 외륜 손상. 고속 주행 시 윙 소리 발생.',
      color: const Color(0xFF3498DB),
    ),
    _DemoPattern(
      name: '변속기 기어 마모',
      nameEn: 'Gear Wear',
      component: 'transmission',
      status: 'warning',
      faultCode: 'gear_wear',
      dominantFreq: 450.0,
      rms: 0.38,
      description: '변속기 기어 마모. 변속 시 소음과 진동 발생.',
      color: const Color(0xFF9B59B6),
    ),
    _DemoPattern(
      name: '브레이크 로터 변형',
      nameEn: 'Rotor Warp',
      component: 'brake',
      status: 'critical',
      faultCode: 'rotor_warp',
      dominantFreq: 180.0,
      rms: 0.55,
      description: '브레이크 로터 열 변형. 제동 시 떨림 발생.',
      color: const Color(0xFFE74C3C),
    ),
    _DemoPattern(
      name: '배기 누출',
      nameEn: 'Exhaust Leak',
      component: 'exhaust',
      status: 'warning',
      faultCode: 'exhaust_leak',
      dominantFreq: 75.0,
      rms: 0.42,
      description: '배기 파이프 누출. 엔진 근처에서 탁탁 소리 발생.',
      color: const Color(0xFF2ECC71),
    ),
    _DemoPattern(
      name: '정상 상태',
      nameEn: 'Normal State',
      component: 'engine',
      status: 'normal',
      faultCode: 'engine_ok',
      dominantFreq: 45.0,
      rms: 0.12,
      description: '정상 작동 상태. 이상 소음 없음.',
      color: const Color(0xFF00C896),
    ),
  ];

  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('패턴 업로드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoBanner(),
            const SizedBox(height: 20),
            const Text(
              '사전 정의된 고장 패턴',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._patterns.map((p) => _PatternCard(
                  pattern: p,
                  isUploading: _isUploading,
                  onUpload: () => _uploadPattern(p),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPattern(_DemoPattern pattern) async {
    setState(() => _isUploading = true);

    final auth = context.read<AuthProvider>();
    final trainer = context.read<TrainerProvider>();
    trainer.updateFromAuth(auth.serverUrl, auth.token);

    // Generate synthetic audio samples for the pattern
    final samples = _generateSyntheticSamples(pattern.dominantFreq, pattern.rms);

    final success = await trainer.teachKnowledge(
      component: pattern.component,
      correctStatus: pattern.status,
      correctFaultCode: pattern.faultCode,
      notes: pattern.description,
      vehicleType: 'sedan',
      samples: samples,
      dominantFreq: pattern.dominantFreq,
      rms: pattern.rms,
    );

    if (!mounted) return;
    setState(() => _isUploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            success ? '✅ "${pattern.name}" 패턴이 저장되었습니다!' : '❌ 저장 실패'),
        backgroundColor: success ? const Color(0xFF00C896) : Colors.red,
      ),
    );
  }

  List<double> _generateSyntheticSamples(double freq, double rms) {
    final random = math.Random();
    final sampleRate = 44100;
    final durationMs = 2000;
    final n = (sampleRate * durationMs / 1000).round();
    final samples = List<double>.generate(n, (i) {
      final t = i / sampleRate;
      // Primary frequency component
      final signal = rms * math.sin(2 * math.pi * freq * t);
      // Harmonics
      final harmonic2 = rms * 0.3 * math.sin(2 * math.pi * freq * 2 * t);
      final harmonic3 = rms * 0.1 * math.sin(2 * math.pi * freq * 3 * t);
      // Noise
      final noise = (random.nextDouble() - 0.5) * rms * 0.1;
      return (signal + harmonic2 + harmonic3 + noise).clamp(-1.0, 1.0);
    });
    return samples;
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title:
            const Text('패턴 업로드 안내', style: TextStyle(color: Colors.white)),
        content: const Text(
          '사전 정의된 고장 패턴을 닥터브릉이 지식베이스에 추가합니다.\n\n'
          '각 패턴은 합성 오디오 신호를 생성하여 서버에 전송합니다. '
          '이를 통해 AI가 해당 고장 패턴을 인식하는 능력을 갖추게 됩니다.\n\n'
          '실제 차량 소리 데이터를 사용하면 더 정확한 학습이 가능합니다.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인',
                style: TextStyle(color: Color(0xFF00C896))),
          ),
        ],
      ),
    );
  }
}

class _DemoPattern {
  final String name;
  final String nameEn;
  final String component;
  final String status;
  final String faultCode;
  final double dominantFreq;
  final double rms;
  final String description;
  final Color color;

  _DemoPattern({
    required this.name,
    required this.nameEn,
    required this.component,
    required this.status,
    required this.faultCode,
    required this.dominantFreq,
    required this.rms,
    required this.description,
    required this.color,
  });
}

class _PatternCard extends StatelessWidget {
  final _DemoPattern pattern;
  final bool isUploading;
  final VoidCallback onUpload;

  const _PatternCard({
    required this.pattern,
    required this.isUploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(pattern.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pattern.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Component icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: pattern.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _componentIcon(pattern.component),
              color: pattern.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pattern.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppConstants.statusNames[pattern.status]!
                            .split(' ')
                            .first,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  pattern.description,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Chip('${pattern.dominantFreq.toStringAsFixed(0)} Hz'),
                    const SizedBox(width: 6),
                    _Chip('RMS: ${pattern.rms.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Upload button
          ElevatedButton(
            onPressed: isUploading ? null : onUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: pattern.color,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(60, 36),
            ),
            child: isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.black, strokeWidth: 2))
                : const Text('업로드', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  IconData _componentIcon(String comp) {
    switch (comp) {
      case 'engine': return Icons.settings;
      case 'transmission': return Icons.swap_horiz;
      case 'bearing': return Icons.radio_button_checked;
      case 'brake': return Icons.stop_circle;
      case 'exhaust': return Icons.air;
      case 'belt': return Icons.loop;
      default: return Icons.build;
    }
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white54, fontSize: 11)),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0088FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF0088FF).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.upload_file, color: Color(0xFF0088FF), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '표준 고장 패턴을 서버에 업로드하여 닥터브릉이 AI의 초기 지식을 구축합니다. '
              '각 패턴을 클릭하면 합성 신호를 생성하여 서버에 전송합니다.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

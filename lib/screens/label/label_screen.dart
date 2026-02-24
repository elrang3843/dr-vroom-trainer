/// Label Screen — Core training functionality
/// Trainers can manually input sound characteristics and label them
/// to teach the AI model about vehicle fault patterns
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trainer_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class LabelScreen extends StatefulWidget {
  const LabelScreen({super.key});

  @override
  State<LabelScreen> createState() => _LabelScreenState();
}

class _LabelScreenState extends State<LabelScreen> {
  final _formKey = GlobalKey<FormState>();

  // Selected values
  String _selectedComponent = 'engine';
  String _selectedStatus = 'normal';
  String _selectedFaultCode = 'engine_ok';

  // Input controllers
  final _notesCtrl = TextEditingController();
  final _dominantFreqCtrl = TextEditingController();
  final _rmsCtrl = TextEditingController();
  final _vehicleTypeCtrl = TextEditingController(text: 'sedan');

  @override
  void dispose() {
    _notesCtrl.dispose();
    _dominantFreqCtrl.dispose();
    _rmsCtrl.dispose();
    _vehicleTypeCtrl.dispose();
    super.dispose();
  }

  void _onComponentChanged(String? comp) {
    if (comp == null) return;
    setState(() {
      _selectedComponent = comp;
      final codes = AppConstants.faultCodes[comp] ?? [];
      _selectedFaultCode = codes.isNotEmpty ? codes.first : '';
    });
  }

  Future<void> _submitLabel() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final trainer = context.read<TrainerProvider>();
    trainer.updateFromAuth(auth.serverUrl, auth.token);

    final success = await trainer.teachKnowledge(
      component: _selectedComponent,
      correctStatus: _selectedStatus,
      correctFaultCode: _selectedFaultCode,
      notes: _notesCtrl.text.trim(),
      vehicleType: _vehicleTypeCtrl.text.trim(),
      dominantFreq: double.tryParse(_dominantFreqCtrl.text),
      rms: double.tryParse(_rmsCtrl.text),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(trainer.successMessage ?? '저장 완료!'),
          backgroundColor: const Color(0xFF00C896),
          duration: const Duration(seconds: 3),
        ),
      );
      _resetForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(trainer.errorMessage ?? '저장 실패'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    _notesCtrl.clear();
    _dominantFreqCtrl.clear();
    _rmsCtrl.clear();
    setState(() {
      _selectedComponent = 'engine';
      _selectedStatus = 'normal';
      _selectedFaultCode = 'engine_ok';
    });
  }

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();
    final faultCodes =
        AppConstants.faultCodes[_selectedComponent] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('지식 레이블링'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header info
              _InfoBanner(),
              const SizedBox(height: 20),

              // Step 1: Vehicle type
              _SectionHeader(step: '1', title: '차량 정보'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vehicleTypeCtrl,
                decoration: const InputDecoration(
                  labelText: '차량 종류',
                  prefixIcon: Icon(Icons.directions_car),
                  hintText: 'sedan / suv / truck / van',
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),

              // Step 2: Component selection
              _SectionHeader(step: '2', title: '진단 부품'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.components.map((comp) {
                  final isSelected = _selectedComponent == comp;
                  return GestureDetector(
                    onTap: () => _onComponentChanged(comp),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.componentColor(comp).withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.componentColor(comp)
                              : Colors.white24,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.componentColor(comp),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppConstants.componentNames[comp]!
                                .split(' ')
                                .first,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.componentColor(comp)
                                  : Colors.white70,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Step 3: Status
              _SectionHeader(step: '3', title: '상태 등급'),
              const SizedBox(height: 12),
              Row(
                children: AppConstants.statusOptions.map((status) {
                  final isSelected = _selectedStatus == status;
                  final color = AppTheme.statusColor(status);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedStatus = status),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              status == 'normal'
                                  ? Icons.check_circle
                                  : status == 'warning'
                                      ? Icons.warning
                                      : Icons.error,
                              color: color,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppConstants.statusNames[status]!
                                  .split(' ')
                                  .first,
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Step 4: Fault code
              _SectionHeader(step: '4', title: '고장 코드'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: faultCodes.contains(_selectedFaultCode)
                        ? _selectedFaultCode
                        : (faultCodes.isNotEmpty ? faultCodes.first : null),
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1A2E),
                    items: faultCodes.map((code) {
                      return DropdownMenuItem(
                        value: code,
                        child: Text(
                          code,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _selectedFaultCode = v ?? ''),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Step 5: Audio features (optional)
              _SectionHeader(step: '5', title: '음향 특징 (선택)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dominantFreqCtrl,
                      decoration: const InputDecoration(
                        labelText: '주요 주파수 (Hz)',
                        prefixIcon: Icon(Icons.waves),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _rmsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'RMS 진폭',
                        prefixIcon: Icon(Icons.timeline),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Step 6: Notes
              _SectionHeader(step: '6', title: '설명 / 메모'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '이 소리 패턴에 대한 설명',
                  prefixIcon: Icon(Icons.notes),
                  hintText: '예: 저속 주행 시 엔진에서 노킹 소리 발생, 30Hz 부근 피크...',
                ),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                validator: (v) =>
                    v?.isEmpty == true ? '설명을 입력하세요' : null,
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: trainer.isLoading ? null : _submitLabel,
                  icon: trainer.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: const Text(
                    '닥터브릉이에게 가르치기',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('레이블링 가이드',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          '레이블링은 닥터브릉이 AI에게 차량 소리 패턴과 그 의미를 가르치는 과정입니다.\n\n'
          '1. 차량 종류를 선택하세요\n'
          '2. 진단할 부품을 선택하세요\n'
          '3. 상태 등급을 지정하세요 (정상/주의/위험)\n'
          '4. 구체적인 고장 코드를 선택하세요\n'
          '5. 음향 특징값을 입력하면 더 정확한 학습이 가능합니다\n'
          '6. 상세한 설명을 작성하세요\n\n'
          '당신이 가르친 내용은 모든 클라이언트가 더 나은 진단을 받을 수 있게 도와줍니다!',
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

// ─── Widget Helpers ───────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF00C896).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb, color: Color(0xFF00C896), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '여기서 입력하는 정보는 닥터브릉이 AI의 지식베이스에 즉시 반영됩니다. '
              '정확한 레이블을 입력할수록 AI 진단 정확도가 높아집니다.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String step;
  final String title;
  const _SectionHeader({required this.step, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF00C896),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Review Screen — Browse and manage existing knowledge
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trainer_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  String? _filterComponent;
  String? _filterStatus;
  bool _expertOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final trainer = context.read<TrainerProvider>();
    trainer.updateFromAuth(auth.serverUrl, auth.token);
    await trainer.loadKnowledgeList(
      component: _filterComponent,
      status: _filterStatus,
      expertOnly: _expertOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<TrainerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('지식 검토'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters
          if (_filterComponent != null || _filterStatus != null || _expertOnly)
            _ActiveFilters(
              component: _filterComponent,
              status: _filterStatus,
              expertOnly: _expertOnly,
              onClear: () {
                setState(() {
                  _filterComponent = null;
                  _filterStatus = null;
                  _expertOnly = false;
                });
                _loadData();
              },
            ),

          // Knowledge list
          Expanded(
            child: trainer.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF00C896)))
                : trainer.knowledgeList.isEmpty
                    ? _EmptyState(onRefresh: _loadData)
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: trainer.knowledgeList.length,
                          itemBuilder: (ctx, i) => _KnowledgeCard(
                            item: trainer.knowledgeList[i],
                            onDelete: (id) async {
                              final confirm = await _confirmDelete(ctx);
                              if (confirm == true) {
                                await trainer.deleteKnowledge(id);
                              }
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title:
            const Text('필터', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('부품',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                _FilterChip(
                    label: '전체',
                    selected: _filterComponent == null,
                    onTap: () => setState(() => _filterComponent = null)),
                ...AppConstants.components.map((c) => _FilterChip(
                      label: AppConstants.componentNames[c]!.split(' ').first,
                      selected: _filterComponent == c,
                      onTap: () => setState(() => _filterComponent = c),
                    )),
              ],
            ),
            const SizedBox(height: 16),
            const Text('상태',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                _FilterChip(
                    label: '전체',
                    selected: _filterStatus == null,
                    onTap: () => setState(() => _filterStatus = null)),
                ...AppConstants.statusOptions.map((s) => _FilterChip(
                      label: AppConstants.statusNames[s]!.split(' ').first,
                      selected: _filterStatus == s,
                      onTap: () => setState(() => _filterStatus = s),
                    )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('전문가 확인만',
                    style: TextStyle(color: Colors.white70)),
                const Spacer(),
                Switch(
                  value: _expertOnly,
                  onChanged: (v) => setState(() => _expertOnly = v),
                  activeThumbColor: const Color(0xFF00C896),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('적용',
                style: TextStyle(color: Color(0xFF00C896))),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext ctx) {
    return showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title:
            const Text('삭제 확인', style: TextStyle(color: Colors.white)),
        content: const Text(
          '이 지식을 삭제하면 닥터브릉이가 이 패턴을 잊어버립니다. 계속할까요?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child:
                const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('삭제',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeCard extends StatelessWidget {
  final KnowledgeItem item;
  final Function(String) onDelete;
  const _KnowledgeCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(item.status);
    final componentColor = AppTheme.componentColor(item.component);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: componentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppConstants.componentNames[item.component]!
                      .split(' ')
                      .first,
                  style: TextStyle(
                      color: componentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppConstants.statusNames[item.status]!.split(' ').first,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              if (item.confirmedByExpert)
                const Icon(Icons.verified,
                    color: Color(0xFF0088FF), size: 16),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 18),
                onPressed: () => onDelete(item.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.faultCode,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.description,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoChip(Icons.waves,
                  '${item.dominantFreq.toStringAsFixed(0)} Hz'),
              const SizedBox(width: 8),
              _InfoChip(Icons.repeat, '${item.sampleCount}회'),
              const SizedBox(width: 8),
              _InfoChip(Icons.star,
                  '${(item.confidence * 100).toStringAsFixed(0)}%'),
              const SizedBox(width: 8),
              _InfoChip(Icons.person,
                  item.source == 'expert' ? '전문가' : item.source),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 12),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  final String? component;
  final String? status;
  final bool expertOnly;
  final VoidCallback onClear;
  const _ActiveFilters({
    this.component,
    this.status,
    required this.expertOnly,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1A1A2E),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Color(0xFF00C896), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              [
                if (component != null) '부품: $component',
                if (status != null) '상태: $status',
                if (expertOnly) '전문가 확인만',
              ].join(' • '),
              style: const TextStyle(color: Color(0xFF00C896), fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, color: Colors.white38, size: 16),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00C896).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected
                  ? const Color(0xFF00C896)
                  : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: selected ? const Color(0xFF00C896) : Colors.white54,
              fontSize: 12),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.psychology_outlined,
              color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          const Text('아직 저장된 지식이 없습니다',
              style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('레이블 탭에서 새로운 지식을 가르쳐 주세요',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: onRefresh, child: const Text('새로고침')),
        ],
      ),
    );
  }
}

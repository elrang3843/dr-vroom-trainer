/// Trainer Provider — manages knowledge labeling and training data
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class KnowledgeItem {
  final String id;
  final String component;
  final String status;
  final String faultCode;
  final String description;
  final double confidence;
  final double dominantFreq;
  final int sampleCount;
  final bool confirmedByExpert;
  final String source;

  KnowledgeItem({
    required this.id,
    required this.component,
    required this.status,
    required this.faultCode,
    required this.description,
    required this.confidence,
    required this.dominantFreq,
    required this.sampleCount,
    required this.confirmedByExpert,
    required this.source,
  });

  factory KnowledgeItem.fromJson(Map<String, dynamic> json) {
    return KnowledgeItem(
      id: json['id'] ?? '',
      component: json['component'] ?? '',
      status: json['status'] ?? 'unknown',
      faultCode: json['fault_code'] ?? '',
      description: json['description'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      dominantFreq: (json['dominant_freq'] ?? 0.0).toDouble(),
      sampleCount: json['sample_count'] ?? 1,
      confirmedByExpert: json['confirmed_by_expert'] ?? false,
      source: json['source'] ?? 'client',
    );
  }
}

class KnowledgeStats {
  final int totalKnowledge;
  final int confirmedByExpert;
  final double avgConfidence;
  final Map<String, int> byComponent;
  final Map<String, int> byStatus;
  final int totalDiagnosticSessions;

  KnowledgeStats({
    required this.totalKnowledge,
    required this.confirmedByExpert,
    required this.avgConfidence,
    required this.byComponent,
    required this.byStatus,
    required this.totalDiagnosticSessions,
  });

  factory KnowledgeStats.fromJson(Map<String, dynamic> json) {
    return KnowledgeStats(
      totalKnowledge: json['total_knowledge'] ?? 0,
      confirmedByExpert: json['confirmed_by_expert'] ?? 0,
      avgConfidence: (json['avg_confidence'] ?? 0.0).toDouble(),
      byComponent: Map<String, int>.from(json['by_component'] ?? {}),
      byStatus: Map<String, int>.from(json['by_status'] ?? {}),
      totalDiagnosticSessions: json['total_diagnostic_sessions'] ?? 0,
    );
  }
}

class TrainerProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  List<KnowledgeItem> _knowledgeList = [];
  KnowledgeStats? _stats;
  String _serverUrl = AppConstants.defaultServerUrl;
  String? _token;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<KnowledgeItem> get knowledgeList => _knowledgeList;
  KnowledgeStats? get stats => _stats;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString(AppConstants.serverUrlKey) ?? AppConstants.defaultServerUrl;
    _token = prefs.getString('auth_token');
  }

  void updateFromAuth(String serverUrl, String? token) {
    _serverUrl = serverUrl;
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ─── Knowledge Fetching ────────────────────────────────────────────────────

  Future<void> loadKnowledgeStats() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/api/v1/knowledge/stats'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _stats = KnowledgeStats.fromJson(data['stats'] ?? data);
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = '통계 로딩 실패: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadKnowledgeList({
    String? component,
    String? status,
    bool expertOnly = false,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      var url = '$_serverUrl/api/v1/knowledge/list?limit=200';
      if (component != null) url += '&component=$component';
      if (status != null) url += '&status=$status';
      if (expertOnly) url += '&expert_only=true';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        _knowledgeList = list.map((e) => KnowledgeItem.fromJson(e)).toList();
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = '지식 목록 로딩 실패: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Teaching / Labeling ──────────────────────────────────────────────────

  Future<bool> teachKnowledge({
    required String component,
    required String correctStatus,
    required String correctFaultCode,
    required String notes,
    String vehicleType = 'unknown',
    List<double>? samples,
    double? dominantFreq,
    double? rms,
    String? sessionId,
  }) async {
    _isLoading = true;
    _successMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = jsonEncode({
        'trainer_id': 'trainer_${DateTime.now().millisecondsSinceEpoch}',
        'session_id': sessionId,
        'component': component,
        'correct_status': correctStatus,
        'correct_fault_code': correctFaultCode,
        'notes': notes,
        'vehicle_type': vehicleType,
        if (samples != null) 'samples': samples,
        if (dominantFreq != null) 'dominant_freq': dominantFreq,
        if (rms != null) 'rms': rms,
      });

      final response = await http.post(
        Uri.parse('$_serverUrl/api/v1/knowledge/teach'),
        headers: _headers,
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _successMessage = data['message'] ?? '지식이 저장되었습니다!';
        await loadKnowledgeStats();
        return true;
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? '저장 실패';
        return false;
      }
    } catch (e) {
      _errorMessage = '서버 오류: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete incorrect knowledge
  Future<bool> deleteKnowledge(String knowledgeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_serverUrl/api/v1/knowledge/$knowledgeId?trainer_id=trainer'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _knowledgeList.removeWhere((k) => k.id == knowledgeId);
        _successMessage = '지식이 삭제되었습니다.';
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = '삭제 실패: $e';
      notifyListeners();
    }
    return false;
  }

  void clearMessages() {
    _successMessage = null;
    _errorMessage = null;
    notifyListeners();
  }
}

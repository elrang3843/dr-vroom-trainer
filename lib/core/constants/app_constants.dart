/// App Constants for Dr. Vroom Trainer
class AppConstants {
  // App Identity
  static const String appName = 'Dr. Vroom Trainer';
  static const String appNameKr = '닥터브릉이 교육';
  static const String version = '1.0.0';
  static const String patentNo = 'US 12,349,291 B2';

  // Hive boxes
  static const String sessionsBoxName = 'trainer_sessions';
  static const String settingsBoxName = 'trainer_settings';

  // Server config key
  static const String serverUrlKey = 'server_url';
  static const String defaultServerUrl = 'http://localhost:8000';

  // Components
  static const List<String> components = [
    'engine',
    'transmission',
    'bearing',
    'brake',
    'exhaust',
    'belt',
  ];

  static const Map<String, String> componentNames = {
    'engine': '엔진 (Engine)',
    'transmission': '변속기 (Transmission)',
    'bearing': '베어링 (Bearing)',
    'brake': '브레이크 (Brake)',
    'exhaust': '배기 (Exhaust)',
    'belt': '벨트/풀리 (Belt/Pulley)',
  };

  static const List<String> statusOptions = ['normal', 'warning', 'critical'];

  static const Map<String, String> statusNames = {
    'normal': '정상 (Normal)',
    'warning': '주의 (Warning)',
    'critical': '위험 (Critical)',
  };

  // Fault codes per component
  static const Map<String, List<String>> faultCodes = {
    'engine': ['engine_ok', 'engine_misfire', 'engine_knock', 'engine_oil_starvation'],
    'transmission': ['transmission_ok', 'gear_wear', 'gear_slip', 'clutch_wear'],
    'bearing': ['bearing_ok', 'bearing_outer_race', 'bearing_inner_race', 'bearing_ball_defect'],
    'brake': ['brake_ok', 'rotor_warp', 'pad_wear', 'caliper_stick'],
    'exhaust': ['exhaust_ok', 'exhaust_leak', 'muffler_damage', 'cat_clog'],
    'belt': ['belt_ok', 'belt_wear', 'belt_slip', 'pulley_misalign'],
  };
}

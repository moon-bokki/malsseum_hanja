/// 빌드 시 --dart-define 으로 주입하는 설정값.
///
/// flutter run --dart-define=USE_FIREBASE=true --dart-define=STDICT_API_KEY=발급받은키
class AppConfig {
  AppConfig._();

  /// false 이면 Firebase 없이 메모리 저장소로 실행된다 (설정 전 개발/테스트용).
  static const bool useFirebase = bool.fromEnvironment('USE_FIREBASE');

  /// 국립국어원 표준국어대사전 Open API 인증키.
  static const String stdictApiKey = String.fromEnvironment('STDICT_API_KEY');

  static const String stdictBaseUrl = 'https://stdict.korean.go.kr';

  /// FCM 토픽: 매일 아침 오늘의 말씀 알림.
  static const String dailyVerseTopic = 'daily_verse';
}

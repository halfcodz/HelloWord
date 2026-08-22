/// 웹이 아닌 곳(iOS·안드로이드 앱)에서는 새 버전을 여기서 확인하지 않는다.
/// 스토어가 알아서 알려 주기 때문이다.
Future<String?> fetchServerVersion(String cacheBuster) async => null;

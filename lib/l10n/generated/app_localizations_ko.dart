// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => '맵애니타임 마켓';

  @override
  String get login => '로그인';

  @override
  String get logout => '로그아웃';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get welcomeBack => '다시 오신 것을 환영합니다';

  @override
  String get signInToContinue => '계속하려면 로그인하세요';

  @override
  String get loginHint => '힌트: 아무 이메일 주소 + 6자 이상의 비밀번호';

  @override
  String get home => '홈';

  @override
  String get profile => '프로필';

  @override
  String get worldMap => '세계 지도';

  @override
  String get errorNoOrderId => '오류: 주문 ID가 제공되지 않았습니다';

  @override
  String get errorNoOrder => '오류: 주문이 제공되지 않았습니다';

  @override
  String get errorNoStore => '오류: 매장이 제공되지 않았습니다';

  @override
  String get errorNoProduct => '오류: 상품이 제공되지 않았습니다';

  @override
  String get description => '설명';

  @override
  String get clearCartPrompt => '장바구니를 비우시겠습니까?';

  @override
  String get cancel => '취소';

  @override
  String productAddedToCart(String productName) {
    return '$productName이(가) 장바구니에 추가되었습니다';
  }

  @override
  String get clearAndAdd => '비우고 추가';

  @override
  String get shareComingSoon => '공유하기 기능 곧 제공 예정';

  @override
  String get comingSoon => '곧 제공 예정';

  @override
  String get notifications => '알림';

  @override
  String get retry => '다시 시도';

  @override
  String get cart => '장바구니';

  @override
  String get orderPlacedSuccess => '주문이 성공적으로 완료되었습니다!';

  @override
  String orderPlacedFailed(String error) {
    return '주문 처리에 실패했습니다: $error';
  }
}

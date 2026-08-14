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
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get dontHaveAccount => '계정이 없으신가요?';

  @override
  String get signUp => '회원가입';

  @override
  String get createAccount => '계정 만들기';

  @override
  String get joinTagline => '구매자로 맵애니타임 마켓에 가입하세요';

  @override
  String get fullNameOptional => '이름 (선택 사항)';

  @override
  String get createAccountCta => '계정 만들기';

  @override
  String get accountCreatedPleaseLogin => '계정이 생성되었습니다. 로그인해 주세요.';

  @override
  String get alreadyHaveAccount => '이미 계정이 있으신가요?';

  @override
  String get logIn => '로그인';

  @override
  String get forgotPasswordTitle => '비밀번호 재설정';

  @override
  String get forgotPasswordSubtitle => '이메일을 입력하시면 인증 코드를 보내드립니다';

  @override
  String get sendCode => '코드 보내기';

  @override
  String get resetCodeSent => '인증 코드가 전송되었습니다. 이메일을 확인해 주세요.';

  @override
  String get resetPasswordTitle => '인증 코드 입력';

  @override
  String resetPasswordSubtitle(String email) {
    return '$email로 6자리 코드를 보냈습니다';
  }

  @override
  String get verificationCode => '인증 코드';

  @override
  String get verificationCodeInvalid => '4자리 코드를 입력하세요';

  @override
  String get signInCta => '로그인';

  @override
  String get signUpCta => '가입하기';

  @override
  String get nextCta => '다음';

  @override
  String get acceptTerms => '이용약관 및 개인정보처리방침에 동의합니다';

  @override
  String get registerStepEmailTitle => '이메일이 무엇인가요?';

  @override
  String get registerStepEmailSubtitle => '계정을 안전하게 보호하는 데 사용됩니다.';

  @override
  String get registerStepNameTitle => '이름이 무엇인가요?';

  @override
  String get registerStepNameSubtitle => '맞춤 경험을 위해 도움이 됩니다.';

  @override
  String get registerStepPasswordTitle => '비밀번호 만들기';

  @override
  String get registerStepPasswordSubtitle => '6자 이상으로 설정해 주세요.';

  @override
  String get newPassword => '새 비밀번호';

  @override
  String get confirmPassword => '비밀번호 확인';

  @override
  String get resetPasswordCta => '비밀번호 재설정';

  @override
  String get passwordResetSuccess => '비밀번호가 재설정되었습니다. 로그인해 주세요.';

  @override
  String get passwordsDoNotMatch => '비밀번호가 일치하지 않습니다';

  @override
  String get errorNoEmail => '오류: 이메일이 제공되지 않았습니다';

  @override
  String get orSignInWith => '또는 다음으로 로그인';

  @override
  String get continueWithGoogle => 'Google로 계속하기';

  @override
  String get registerSuccessTitle => '성공!';

  @override
  String get registerSuccessSubtitle => '계정이 준비되었습니다. 주변 매장을 둘러보세요.';

  @override
  String get continueButton => '계속';

  @override
  String get authTaglineDiscover => '실시간 지도에서 주변 매장을 발견하세요';

  @override
  String get authTaglineTrack => '실시간으로 픽업 상태를 추적하세요';

  @override
  String get authTaglineCheckout => '필리핀 페소로 안전하게 결제하세요';

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

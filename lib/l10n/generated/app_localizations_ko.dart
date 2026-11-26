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
  String get wordmark => 'MapAnytime';

  @override
  String get login => '로그인';

  @override
  String get logout => '로그아웃';

  @override
  String get email => '이메일';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => '비밀번호';

  @override
  String get enterPasswordHint => '비밀번호를 입력하세요';

  @override
  String get createPasswordHint => '8자 이상';

  @override
  String get confirmPasswordHint => '비밀번호를 다시 입력하세요';

  @override
  String get welcomeBack => '다시 오신 것을 환영합니다';

  @override
  String get signInToContinue => '이전에 하던 곳부터 다시 시작하세요.';

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
  String get firstName => '이름';

  @override
  String get firstNameHint => 'Juan';

  @override
  String get middleName => '중간 이름 (선택 사항)';

  @override
  String get middleNameHint => 'Santos';

  @override
  String get lastName => '성';

  @override
  String get lastNameHint => 'Dela Cruz';

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
  String get forgotPasswordSubtitle => '이메일을 입력하시면 6자리 코드를 보내드립니다.';

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
  String get registerStepAccountTitle => '계정 만들기';

  @override
  String get registerStepAccountSubtitle => '유효한 신분증에 적힌 그대로 이름을 입력하세요.';

  @override
  String get phoneNumber => '전화번호';

  @override
  String get phoneNumberHint => '917 123 4567';

  @override
  String get idNameMismatch =>
      '신분증의 이름이 입력한 이름과 일치하지 않습니다. 정보를 다시 확인하고 업로드한 신분증의 이름과 같은지 확인해 주세요.';

  @override
  String get idEditName => '이름 수정';

  @override
  String get registerStepPasswordTitle => '비밀번호 만들기';

  @override
  String get registerStepPasswordSubtitle => '8자 이상. 길수록 더 안전합니다.';

  @override
  String get registerStepIdTitle => '유효한 신분증 업로드';

  @override
  String get registerStepIdSubtitle => '신분증에서 정보를 읽어 입력할 내용을 줄여 드려요.';

  @override
  String get registerStepReviewTitle => '정보 확인';

  @override
  String get registerStepReviewSubtitle => '신분증에서 읽은 정보예요. 틀린 부분을 수정하세요.';

  @override
  String get idFrontOfId => '신분증 앞면';

  @override
  String get idTakePhoto => '사진 촬영';

  @override
  String get idTakePhotoHint => '카메라 사용';

  @override
  String get idChooseGallery => '갤러리에서 선택';

  @override
  String get idChooseGalleryHint => '저장된 사진 선택';

  @override
  String get idAcceptedIds => '사용 가능한 신분증';

  @override
  String get idTipFlat => '평평한 곳에 신분증을 놓으세요';

  @override
  String get idTipCorners => '네 모서리가 모두 프레임 안에 들어오게 하세요';

  @override
  String get idTipGlare => '글자가 잘 보이도록 빛 반사를 피하세요';

  @override
  String get idPrivacyHint => '신분증은 정보 입력과 확인에만 사용됩니다.';

  @override
  String get idReading => '신분증을 읽는 중…';

  @override
  String get idReadingHint => '몇 초 걸려요. 다음 화면에서 모두 확인할 수 있어요.';

  @override
  String get idUseDifferentPhoto => '다른 사진 사용';

  @override
  String get idCameraDenied => '사진을 찍으려면 설정에서 카메라 접근을 허용하세요.';

  @override
  String get idPhotosDenied => '사진을 선택하려면 설정에서 사진 접근을 허용하세요.';

  @override
  String get idRejectedUnreadable =>
      '이 사진을 읽을 수 없어요. 신분증 전체가 프레임 안에 들어오고, 초점이 맞고, 빛 반사가 없도록 다시 찍어 주세요.';

  @override
  String get idRejectedNotAnId => '사용 가능한 신분증이 아닌 것 같아요. 아래 목록의 신분증을 사용해 주세요.';

  @override
  String get idPhotoAdded => '사진 추가됨';

  @override
  String get idRetake => '다시 찍기';

  @override
  String get idReviewBanner =>
      '\'신분증에서\'로 표시된 항목은 사진에서 채워졌어요. 계속하기 전에 항목을 눌러 수정하세요.';

  @override
  String get idGroupName => '이름';

  @override
  String get idGroupPersonal => '개인 정보';

  @override
  String get idGroupId => '신분증';

  @override
  String get dateOfBirth => '생년월일';

  @override
  String get dateOfBirthHint => '날짜 선택';

  @override
  String get sex => '성별';

  @override
  String get sexMale => '남성';

  @override
  String get sexFemale => '여성';

  @override
  String get address => '주소';

  @override
  String get addressHint => '번지, 도로명, 바랑가이, 시, 주';

  @override
  String get idType => '신분증 종류';

  @override
  String get idTypeHint => '신분증 선택';

  @override
  String get idNumber => '신분증 번호';

  @override
  String get idNumberHint => '신분증에 적힌 그대로';

  @override
  String get sourceFromId => '신분증에서';

  @override
  String get sourceCheck => '확인 필요';

  @override
  String get sourceEdited => '수정됨';

  @override
  String get reviewContinueCta => '확인했어요, 계속';

  @override
  String get reviewNotSubmitted => '아직 제출되지 않았어요. 다음 단계에서 확인합니다.';

  @override
  String get reviewFixFields => '표시된 항목을 수정해야 계속할 수 있어요.';

  @override
  String get editDetails => '정보 수정';

  @override
  String get dateOfBirthFuture => '생년월일은 미래 날짜일 수 없습니다';

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
  String get orSignInWith => '또는';

  @override
  String get continueWithGoogle => 'Google로 계속하기';

  @override
  String get continueWithFacebook => 'Facebook으로 계속하기';

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

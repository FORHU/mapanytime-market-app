// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'MapAnytime Market';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get welcomeBack => '¡Bienvenido de nuevo!';

  @override
  String get signInToContinue => 'Inicia sesión para continuar';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get dontHaveAccount => '¿No tienes una cuenta?';

  @override
  String get signUp => 'Regístrate';

  @override
  String get createAccount => 'Crea tu cuenta';

  @override
  String get joinTagline => 'Únete a MapAnytime Market como comprador';

  @override
  String get fullNameOptional => 'Nombre completo (opcional)';

  @override
  String get createAccountCta => 'Crear cuenta';

  @override
  String get accountCreatedPleaseLogin => 'Cuenta creada. Inicia sesión.';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get logIn => 'Iniciar sesión';

  @override
  String get forgotPasswordTitle => 'Restablece tu contraseña';

  @override
  String get forgotPasswordSubtitle =>
      'Ingresa tu correo electrónico y te enviaremos un código de verificación';

  @override
  String get sendCode => 'Enviar código';

  @override
  String get resetCodeSent =>
      'Código de verificación enviado. Revisa tu correo.';

  @override
  String get resetPasswordTitle => 'Ingresa el código de verificación';

  @override
  String resetPasswordSubtitle(String email) {
    return 'Enviamos un código de 6 dígitos a $email';
  }

  @override
  String get verificationCode => 'Código de verificación';

  @override
  String get verificationCodeInvalid => 'Ingresa el código de 4 dígitos';

  @override
  String get signInCta => 'Iniciar sesión';

  @override
  String get signUpCta => 'Registrarse';

  @override
  String get nextCta => 'Siguiente';

  @override
  String get acceptTerms => 'Acepto los Términos y la Privacidad';

  @override
  String get registerStepEmailTitle => '¿Cuál es tu correo electrónico?';

  @override
  String get registerStepEmailSubtitle =>
      'Lo usaremos para proteger tu cuenta.';

  @override
  String get registerStepNameTitle => '¿Cuál es tu nombre?';

  @override
  String get registerStepNameSubtitle =>
      'Esto ayuda a personalizar tu experiencia.';

  @override
  String get registerStepPasswordTitle => 'Crea una contraseña';

  @override
  String get registerStepPasswordSubtitle =>
      'Debe tener al menos 6 caracteres.';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get resetPasswordCta => 'Restablecer contraseña';

  @override
  String get passwordResetSuccess => 'Contraseña restablecida. Inicia sesión.';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get errorNoEmail => 'Error: no se proporcionó correo electrónico';

  @override
  String get orSignInWith => 'O inicia sesión con';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get registerSuccessTitle => '¡Listo!';

  @override
  String get registerSuccessSubtitle =>
      'Tu cuenta está lista. Empieza a descubrir tiendas cerca de ti.';

  @override
  String get continueButton => 'Continuar';

  @override
  String get authTaglineDiscover =>
      'Descubre tiendas cercanas en el mapa en vivo';

  @override
  String get authTaglineTrack => 'Rastrea tu pedido en tiempo real';

  @override
  String get authTaglineCheckout => 'Paga de forma segura en pesos filipinos';

  @override
  String get home => 'Inicio';

  @override
  String get profile => 'Perfil';

  @override
  String get worldMap => 'Mapa del mundo';

  @override
  String get errorNoOrderId => 'Error: no se proporcionó ID de pedido';

  @override
  String get errorNoOrder => 'Error: no se proporcionó pedido';

  @override
  String get errorNoStore => 'Error: no se proporcionó tienda';

  @override
  String get errorNoProduct => 'Error: no se proporcionó producto';

  @override
  String get description => 'Descripción';

  @override
  String get clearCartPrompt => '¿Deseas vaciar el carrito?';

  @override
  String get cancel => 'Cancelar';

  @override
  String productAddedToCart(String productName) {
    return '$productName se añadió al carrito.';
  }

  @override
  String get clearAndAdd => 'Vaciar y añadir';

  @override
  String get shareComingSoon => 'Compartir (próximamente)';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get retry => 'Reintentar';

  @override
  String get cart => 'Carrito';

  @override
  String get orderPlacedSuccess => '¡Pedido realizado con éxito!';

  @override
  String orderPlacedFailed(String error) {
    return 'Error al realizar el pedido: $error';
  }
}

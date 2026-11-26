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
  String get wordmark => 'MapAnytime';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get email => 'Correo electrónico';

  @override
  String get emailHint => 'tucorreo@ejemplo.com';

  @override
  String get password => 'Contraseña';

  @override
  String get enterPasswordHint => 'Ingresa tu contraseña';

  @override
  String get createPasswordHint => '8+ caracteres';

  @override
  String get confirmPasswordHint => 'Vuelve a ingresarla';

  @override
  String get welcomeBack => '¡Bienvenido de nuevo!';

  @override
  String get signInToContinue => 'Inicia sesión para retomar donde lo dejaste.';

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
  String get firstName => 'Nombre';

  @override
  String get firstNameHint => 'Juan';

  @override
  String get middleName => 'Segundo nombre (opcional)';

  @override
  String get middleNameHint => 'Santos';

  @override
  String get lastName => 'Apellido';

  @override
  String get lastNameHint => 'Dela Cruz';

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
      'Ingresa tu correo electrónico y te enviaremos un código de 6 dígitos.';

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
  String get registerStepAccountTitle => 'Crea tu cuenta';

  @override
  String get registerStepAccountSubtitle =>
      'Usa tu nombre tal como aparece en tu identificación válida.';

  @override
  String get phoneNumber => 'Número de teléfono';

  @override
  String get phoneNumberHint => '917 123 4567';

  @override
  String get idNameMismatch =>
      'El nombre de tu identificación no coincide con el nombre que ingresaste. Revisa tus datos y asegúrate de que tu nombre sea el mismo que aparece en la identificación que subiste.';

  @override
  String get idEditName => 'Editar tu nombre';

  @override
  String get registerStepPasswordTitle => 'Crea una contraseña';

  @override
  String get registerStepPasswordSubtitle =>
      'Al menos 8 caracteres. Cuanto más larga, más segura.';

  @override
  String get registerStepIdTitle => 'Sube una identificación válida';

  @override
  String get registerStepIdSubtitle =>
      'Leeremos tus datos de ella para que escribas menos.';

  @override
  String get registerStepReviewTitle => 'Revisa tus datos';

  @override
  String get registerStepReviewSubtitle =>
      'Leímos estos datos de tu identificación. Corrige lo que no esté bien.';

  @override
  String get idFrontOfId => 'Frente de tu identificación';

  @override
  String get idTakePhoto => 'Tomar una foto';

  @override
  String get idTakePhotoHint => 'Usa tu cámara';

  @override
  String get idChooseGallery => 'Elegir de la galería';

  @override
  String get idChooseGalleryHint => 'Elige una foto guardada';

  @override
  String get idAcceptedIds => 'Identificaciones aceptadas';

  @override
  String get idTipFlat => 'Coloca la identificación sobre una superficie lisa';

  @override
  String get idTipCorners => 'Mantén las cuatro esquinas dentro del marco';

  @override
  String get idTipGlare => 'Evita reflejos para que el texto se lea bien';

  @override
  String get idPrivacyHint =>
      'Tu identificación solo se usa para completar y verificar tus datos.';

  @override
  String get idReading => 'Leyendo tu identificación…';

  @override
  String get idReadingHint =>
      'Tarda unos segundos. Revisarás todo en la siguiente pantalla.';

  @override
  String get idUseDifferentPhoto => 'Usar otra foto';

  @override
  String get idCameraDenied =>
      'Permite el acceso a la cámara en Ajustes para tomar una foto.';

  @override
  String get idPhotosDenied =>
      'Permite el acceso a las fotos en Ajustes para elegir una foto.';

  @override
  String get idRejectedUnreadable =>
      'No pudimos leer esta foto. Vuelve a tomarla con toda la identificación dentro del marco, enfocada y sin reflejos.';

  @override
  String get idRejectedNotAnId =>
      'Esto no parece una identificación aceptada. Usa una de las identificaciones de la lista.';

  @override
  String get idPhotoAdded => 'Foto añadida';

  @override
  String get idRetake => 'Repetir';

  @override
  String get idReviewBanner =>
      'Los campos marcados con «De la ID» se completaron con tu foto. Toca cualquier campo para corregirlo antes de continuar.';

  @override
  String get idGroupName => 'Nombre';

  @override
  String get idGroupPersonal => 'Datos personales';

  @override
  String get idGroupId => 'Identificación';

  @override
  String get dateOfBirth => 'Fecha de nacimiento';

  @override
  String get dateOfBirthHint => 'Elige una fecha';

  @override
  String get sex => 'Sexo';

  @override
  String get sexMale => 'Masculino';

  @override
  String get sexFemale => 'Femenino';

  @override
  String get address => 'Dirección';

  @override
  String get addressHint => 'N.º de casa, calle, barangay, ciudad, provincia';

  @override
  String get idType => 'Tipo de identificación';

  @override
  String get idTypeHint => 'Elige tu identificación';

  @override
  String get idNumber => 'Número de identificación';

  @override
  String get idNumberHint => 'Tal como aparece en tu identificación';

  @override
  String get sourceFromId => 'De la ID';

  @override
  String get sourceCheck => 'Revisa esto';

  @override
  String get sourceEdited => 'Editado';

  @override
  String get reviewContinueCta => 'Todo bien, continuar';

  @override
  String get reviewNotSubmitted =>
      'Aún no se envía nada. Lo confirmarás en el siguiente paso.';

  @override
  String get reviewFixFields => 'Corrige los campos marcados para continuar.';

  @override
  String get editDetails => 'Editar datos';

  @override
  String get dateOfBirthFuture => 'La fecha de nacimiento no puede ser futura';

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
  String get orSignInWith => 'o';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueWithFacebook => 'Continuar con Facebook';

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

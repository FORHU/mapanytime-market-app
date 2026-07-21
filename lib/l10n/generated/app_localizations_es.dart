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
  String get loginHint =>
      'Pista: usa cualquier correo electrónico y una contraseña de al menos 6 caracteres.';

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

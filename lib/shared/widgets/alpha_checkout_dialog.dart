import 'package:flutter/material.dart';

/// Tells a buyer that checkout is closed for alpha testing.
///
/// Shown from the cart before navigating, so the restriction reads as a
/// deliberate message rather than a button that silently does nothing. The
/// route guard in `lib/routes/app_routes.dart` is what actually prevents
/// `CheckoutPage` from mounting; this is the explanation, not the enforcement.
Future<void> showAlphaCheckoutNotice(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Checkout unavailable'),
      content: const Text(
        'MapAnytime is currently in alpha testing and checkout is '
        'temporarily unavailable.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

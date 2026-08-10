import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';

/// Store hero photo preview shown in the map bottom sheet.
class StoreHeroSection extends StatelessWidget {
  const StoreHeroSection({required this.imageUrl, super.key});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return NetworkImageBox(
      url: imageUrl,
      height: 160,
      borderRadius: AppRadius.brLg,
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';

/// A cached network image with premium placeholder + error states.
class NetworkImageBox extends StatelessWidget {
  const NetworkImageBox({
    required this.url,
    this.width = double.infinity,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholderColor,
    super.key,
  });

  final String url;
  final double width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  /// Fill behind the loading spinner and the error icon. Defaults to
  /// `AppColors.ui.surfaceMuted`.
  final Color? placeholderColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, _) =>
            _Placeholder(width: width, height: height, color: placeholderColor),
        errorWidget: (_, _, _) =>
            _ErrorBox(width: width, height: height, color: placeholderColor),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height, this.color});

  final double? width;
  final double? height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color ?? AppColors.ui.surfaceMuted,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.text.tertiary,
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({this.width, this.height, this.color});

  final double? width;
  final double? height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color ?? AppColors.ui.surfaceMuted,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.text.tertiary,
      ),
    );
  }
}

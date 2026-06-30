import 'package:flutter/foundation.dart';

/// Platform capability checks.
///
/// `mapbox_maps_flutter` ships native implementations for Android and iOS only.
/// On every other target (web, Windows, macOS, Linux) initializing or rendering
/// the map throws (e.g. "TargetPlatform.windows is not yet supported by the
/// maps plugin"). Gate all Mapbox usage behind [isMapboxSupported] so the rest
/// of the app stays runnable for development/testing on those platforms.
bool get isMapboxSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

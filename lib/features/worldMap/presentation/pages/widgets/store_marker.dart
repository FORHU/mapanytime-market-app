import 'dart:typed_data';

class StoreMarkerUtils {
  /// Loads a custom marker image as byte array for Mapbox PointAnnotation.
  /// In the future, load your custom assets here.
  static Future<Uint8List> getCustomMarkerBytes() async {
    // Returning an empty array for now; Mapbox will use the default icon
    // or you can load from rootBundle.
    return Uint8List(0);
  }
}

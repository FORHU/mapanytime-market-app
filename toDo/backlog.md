# Map Features Backlog

This document details the planned implementation of map features in the mobile application.

## Open Questions
1. **Google Maps API Key**: Is there an existing Google Maps API key we can use, or should I proceed with the UI using a placeholder key (which will show a blank map but allow the code to be written)?
2. **API Endpoint Details**: For the Express `/api/stores/nearby` endpoint, what is the base URL for the development server? What does the JSON response format look like?
3. **Custom Marker Design**: For the custom map marker component, do you have a specific asset (image/icon) in mind, or should I create a Flutter widget and convert it to a custom marker image dynamically?

## Backlog Tasks

### 1. WorldMap Feature Updates
- [ ] Convert `WorldMapPage` (`lib/features/worldMap/presentation/pages/world_map_page.dart`) to a `ConsumerStatefulWidget` to utilize Riverpod.
- [ ] Add `Set<Marker> _markers` state to render pins on the map.
- [ ] Implement a `showModalBottomSheet` triggered by the `onTap` event of the markers. The bottom sheet will contain the Store Name, Distance, and a "Shop Now" `ElevatedButton`.

### 2. UI Components
- [ ] Create `store_bottom_sheet.dart` (`lib/features/worldMap/presentation/pages/widgets/store_bottom_sheet.dart`) to extract the Bottom-sheet UI into a reusable component.
- [ ] Create `store_marker.dart` (`lib/features/worldMap/presentation/pages/widgets/store_marker.dart`) to generate custom `BitmapDescriptor` markers.

### 3. Data Layer & State Management
- [ ] Create `store_model.dart` (`lib/features/worldMap/domain/models/store_model.dart`) for the Store representing the API response (id, name, lat, lng, distance).
- [ ] Create `store_repository.dart` (`lib/features/worldMap/data/repositories/store_repository.dart`) utilizing `Dio` to make a GET request to `/api/stores/nearby`.
- [ ] Create `world_map_controller.dart` (`lib/features/worldMap/presentation/contollers/world_map_controller.dart`) to implement a Riverpod `StateNotifier` or `AsyncNotifier` to orchestrate fetching stores from the repository.

### 4. Native Configuration
- [ ] Update `AndroidManifest.xml` (`android/app/src/main/AndroidManifest.xml`) to inject the Google Maps API key in the `<application>` tag.
- [ ] Update `AppDelegate.swift` (`ios/Runner/AppDelegate.swift`) to provide the API key to `GMSServices` in the iOS runner.

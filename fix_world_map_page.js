const fs = require('fs');
const filePath = 'lib/features/worldMap/presentation/pages/world_map_page.dart';
let c = fs.readFileSync(filePath, 'utf8');

c = '// ignore_for_file: deprecated_member_use\n' + c;
c = c.replace(/final Map<String, ScreenCoordinate> _storeScreenPositions = \{\};\n/g, 'final Map<String, ScreenCoordinate> _storeScreenPositions = {};\n  String? _selectedStoreId;\n  double _currentZoom = 14;\n');
c = c.replace(/pitch: _is3DMode \? 60\.0 : 0\.0,/g, 'pitch: _is3DMode ? 60 : 0,');
c = c.replace(/\/\/ ignore: deprecated_member_use\n/g, '');

c = c.replace(/pointAnnotationManager\?\.addOnPointAnnotationClickListener\(\s*_PointAnnotationClickListener\(\s*context,\s*ref,\s*_storeIdByAnnotationId,\s*_startNavigationTo,\s*\),\s*\);/g, `pointAnnotationManager?.addOnPointAnnotationClickListener(
        _PointAnnotationClickListener(
          context,
          ref,
          _storeIdByAnnotationId,
          _startNavigationTo,
        ),
      );

      storeCircleAnnotationManager?.addOnCircleAnnotationClickListener(
        _StoreCircleAnnotationClickListener(
          context,
          ref,
          _storeIdByAnnotationId,
          _startNavigationTo,
          (storeId) {
            if (mounted) {
              setState(() {
                _selectedStoreId = storeId;
              });
            }
          },
        ),
      );`);

c = c.replace(/final cameraState = await mapboxMap!\.getCameraState\(\);/g, `final cameraState = await mapboxMap!.getCameraState();
        if (mounted) {
          setState(() {
            _currentZoom = cameraState.zoom;
          });
        }`);

c = c.replace(/final coord = entry\.value;\n\s+final store =/g, `final coord = entry.value;

                  // UX Hybrid Rule: Show ribbon if it is selected, OR if zoom >= 16 and stores < 20
                  final isSelected = storeId == _selectedStoreId;
                  final showOptionalLabels =
                      _currentZoom >= 16.0 && _storeScreenPositions.length < 20;

                  if (!isSelected && !showOptionalLabels) {
                    return const SizedBox.shrink();
                  }

                  final store =`);

c = c.replace(/child: StoreTagWidget\(\n\s+name: store\.name,\n\s+onTap: \(\) \{\n\s+StoreBottomSheet\.show\(\n\s+context,\n\s+store,\n\s+onNavigate: \(\) => \{\},\n\s+\);\n\s+\},\n\s+\),/g, `// Wrap with IgnorePointer so panning gestures fall straight through to the map!
                        child: IgnorePointer(
                          child: StoreTagWidget(
                            name: store.name,
                            onTap: () {},
                          ),
                        ),`);

c = c.replace(/StoreBottomSheet\.show\(context, store, onNavigate: \(\) => onNavigate\(store\)\);/g, `unawaited(
      StoreBottomSheet.show(
        context,
        store,
        onNavigate: () => onNavigate(store),
      ),
    );`);

c += `
class _StoreCircleAnnotationClickListener implements OnCircleAnnotationClickListener {
  _StoreCircleAnnotationClickListener(
    this.context,
    this.ref,
    this.storeIdMap,
    this.onNavigate,
    this.onStoreSelected,
  );

  final BuildContext context;
  final WidgetRef ref;
  final Map<String, String> storeIdMap;
  final void Function(StoreEntity store) onNavigate;
  final void Function(String storeId) onStoreSelected;

  @override
  bool onCircleAnnotationClick(CircleAnnotation annotation) {
    final stores = ref.read(worldMapControllerProvider).valueOrNull ?? [];

    final targetStoreId = storeIdMap[annotation.id];
    if (targetStoreId == null) return false;

    final store = stores.where((s) => s.id == targetStoreId).firstOrNull;
    if (store == null) return false;

    // Update the UI state so the ribbon appears
    onStoreSelected(targetStoreId);

    unawaited(
      StoreBottomSheet.show(
        context,
        store,
        onNavigate: () => onNavigate(store),
      ).whenComplete(() {
        // Clear the selection when the bottom sheet is closed
        onStoreSelected('');
      }),
    );
    return true;
  }
}
`;

fs.writeFileSync(filePath, c);
console.log('Fixed world_map_page.dart successfully');

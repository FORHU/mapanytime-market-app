import zipfile
import os

apk_path = os.path.join('build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk')
print('APK path:', os.path.abspath(apk_path))
print('exists:', os.path.exists(apk_path))

if os.path.exists(apk_path):
    with zipfile.ZipFile(apk_path, 'r') as z:
        names = z.namelist()
        common = [n for n in names if 'com/mapbox/common' in n]
        mapbox = [n for n in names if 'com/mapbox' in n]
        print('APK com/mapbox/common count:', len(common))
        for n in common[:100]:
            print(n)
        print('APK com/mapbox count:', len(mapbox))
        for n in mapbox[:100]:
            print(n)

for p in [
    r'C:\Users\Admin\.gradle\caches\modules-2\files-2.1\com.mapbox.maps\android-ndk27\11.27.0\5c5f888f31465a2d1f0461b9c3167782bc0a46d\android-ndk27-11.27.0.aar',
    r'C:\Users\Admin\.gradle\caches\modules-2\files-2.1\com.mapbox.maps\base-ndk27\11.27.0\6b2c0004015fda4ad8ed36ef2a01650\base-ndk27-11.27.0.aar',
    r'C:\Users\Admin\.gradle\caches\modules-2\files-2.1\com.mapbox.maps\android-core-ndk27\11.27.0\37332d910d5928ccbd885022055431d4e4e9ad01\android-core-ndk27-11.27.0.aar',
    r'C:\Users\Admin\.gradle\caches\modules-2\files-2.1\com.mapbox.common\common-ndk27\24.27.0\accd5904b85d39a427fbffd10179f3f828edd866\common-ndk27-24.27.0.aar',
]:
    print('\n---', p)
    print('exists:', os.path.exists(p))
    if not os.path.exists(p):
        continue
    with zipfile.ZipFile(p, 'r') as z:
        print('entries count:', len(z.namelist()))
        if 'classes.jar' in z.namelist():
            with z.open('classes.jar') as cj:
                with zipfile.ZipFile(cj) as zj:
                    names = zj.namelist()
                    common = [n for n in names if n.startswith('com/mapbox/common')]
                    print('classes.jar common count:', len(common))
                    for n in common[:40]:
                        print('common:', n)
                    mapbox = [n for n in names if n.startswith('com/mapbox')]
                    print('classes.jar com/mapbox count:', len(mapbox))
                    for n in mapbox[:80]:
                        print('mapbox:', n)
        else:
            print('no classes.jar')

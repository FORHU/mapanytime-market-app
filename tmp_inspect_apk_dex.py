import os
import zipfile

apk_path = os.path.join('build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk')
print('APK path:', os.path.abspath(apk_path))
print('exists:', os.path.exists(apk_path))
if not os.path.exists(apk_path):
    raise SystemExit(1)

with zipfile.ZipFile(apk_path, 'r') as z:
    dex_files = [name for name in z.namelist() if name.endswith('.dex')]
    print('dex files:', dex_files)

    for dex_name in dex_files:
        data = z.read(dex_name)
        count = data.count(b'com/mapbox')
        print(f'{dex_name} contains com/mapbox count: {count}')
        if count:
            # collect unique occurrences around matches
            hits = []
            start = 0
            while True:
                idx = data.find(b'com/mapbox', start)
                if idx == -1:
                    break
                snippet = data[max(0, idx-40):idx+120]
                hits.append(snippet)
                start = idx + 1
                if len(hits) >= 20:
                    break
            for i, snippet in enumerate(hits):
                try:
                    text = snippet.decode('utf-8', errors='replace')
                except Exception:
                    text = str(snippet)
                print(i, text)

    # also search the APK zip entries for any Mapbox classes directly
    names = [n for n in z.namelist() if 'com/mapbox' in n]
    print('zip entries with com/mapbox:', len(names))
    for n in names[:100]:
        print(n)

import zipfile
import re

aab = r'C:\Dev\FlutterProjects\autogestion_max\build\app\outputs\bundle\release\app-release.aab'

print("=== Analyzing AAB for READ_MEDIA permissions ===\n")

with zipfile.ZipFile(aab, 'r') as z:
    # List all files that could contain manifest info
    manifest_files = [n for n in z.namelist() if 'manifest' in n.lower() or n.endswith('.xml') or 'proto' in n.lower()]
    print("Files with manifest/xml/proto in name:")
    for f in manifest_files:
        print(f"  {f} ({z.getinfo(f).file_size} bytes)")
    
    print("\n=== Searching ALL files for READ_MEDIA ===")
    for name in z.namelist():
        try:
            data = z.read(name)
            # Search for READ_MEDIA in both text and binary
            if b'READ_MEDIA' in data:
                print(f"\n  FOUND in: {name}")
                # Try to find context
                idx = 0
                while True:
                    idx = data.find(b'READ_MEDIA', idx)
                    if idx == -1:
                        break
                    # Get surrounding bytes
                    start = max(0, idx - 50)
                    end = min(len(data), idx + 60)
                    context = data[start:end]
                    # Try to decode
                    try:
                        text = context.decode('utf-8', errors='replace')
                        print(f"    Context: ...{text}...")
                    except:
                        print(f"    Raw bytes around match at offset {idx}")
                    idx += 10
        except:
            pass

    print("\n=== Searching for android.permission references ===")
    for name in z.namelist():
        try:
            data = z.read(name)
            if b'android.permission' in data:
                # Count specific permissions
                perms_found = []
                for perm in [b'READ_MEDIA_IMAGES', b'READ_MEDIA_VIDEO', b'READ_MEDIA_AUDIO', 
                             b'READ_EXTERNAL_STORAGE', b'WRITE_EXTERNAL_STORAGE', b'CAMERA']:
                    if perm in data:
                        perms_found.append(perm.decode())
                if perms_found:
                    print(f"  {name}: {', '.join(perms_found)}")
        except:
            pass

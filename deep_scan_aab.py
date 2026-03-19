"""
Deep analysis of AAB for READ_MEDIA permissions.
Checks: binary manifest, all XML files, DEX classes, all dependency manifests.
"""
import zipfile
import struct
import re
import os

aab = r'C:\Dev\FlutterProjects\autogestion_max\build\app\outputs\bundle\release\app-release.aab'

print("=" * 70)
print("DEEP AAB PERMISSION ANALYSIS")
print("=" * 70)

with zipfile.ZipFile(aab, 'r') as z:
    # 1. Check the binary AndroidManifest.xml
    print("\n[1] BINARY MANIFEST ANALYSIS")
    print("-" * 40)
    manifest_data = z.read('base/manifest/AndroidManifest.xml')
    
    # Search for permission strings in binary manifest
    perms_to_find = [
        b'READ_MEDIA_IMAGES', b'READ_MEDIA_VIDEO', b'READ_MEDIA_AUDIO',
        b'READ_MEDIA_VISUAL_USER_SELECTED',
        b'READ_EXTERNAL_STORAGE', b'WRITE_EXTERNAL_STORAGE', 
        b'CAMERA', b'CALL_PHONE', b'USE_BIOMETRIC'
    ]
    
    print("Permissions found in base/manifest/AndroidManifest.xml:")
    for perm in perms_to_find:
        count = manifest_data.count(perm)
        status = "FOUND" if count > 0 else "not found"
        marker = "!!!" if perm in [b'READ_MEDIA_IMAGES', b'READ_MEDIA_VIDEO', b'READ_MEDIA_AUDIO'] and count > 0 else "   "
        print(f"  {marker} {perm.decode()}: {status} ({count} occurrences)")

    # 2. Check ALL files in the AAB for READ_MEDIA references
    print("\n[2] FULL AAB SCAN FOR READ_MEDIA")
    print("-" * 40)
    for name in sorted(z.namelist()):
        try:
            data = z.read(name)
            for perm in [b'READ_MEDIA_IMAGES', b'READ_MEDIA_VIDEO', b'READ_MEDIA_AUDIO']:
                if perm in data:
                    print(f"  FOUND {perm.decode()} in: {name} ({len(data)} bytes)")
                    # Show context
                    idx = data.find(perm)
                    start = max(0, idx - 80)
                    end = min(len(data), idx + len(perm) + 80)
                    ctx = data[start:end].decode('utf-8', errors='replace')
                    # Clean up non-printable
                    ctx_clean = ''.join(c if c.isprintable() or c in '\n\t' else '.' for c in ctx)
                    print(f"    Context: {ctx_clean}")
        except Exception as e:
            pass

    # 3. Check all intermediate build manifests
    print("\n[3] CHECKING BUILD INTERMEDIATES")
    print("-" * 40)

build_root = r'C:\Dev\FlutterProjects\autogestion_max\build'
if os.path.exists(build_root):
    for root, dirs, files in os.walk(build_root):
        for f in files:
            if f == 'AndroidManifest.xml':
                fpath = os.path.join(root, f)
                try:
                    with open(fpath, 'r', encoding='utf-8') as fh:
                        content = fh.read()
                    # Check for READ_MEDIA without tools:node="remove"
                    for perm in ['READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO']:
                        if perm in content:
                            # Check if it's a remove directive
                            lines = content.split('\n')
                            for i, line in enumerate(lines):
                                if perm in line:
                                    has_remove = 'tools:node="remove"' in line
                                    rel_path = os.path.relpath(fpath, build_root)
                                    status = "REMOVE directive" if has_remove else "ACTIVE PERMISSION!"
                                    print(f"  {rel_path}")
                                    print(f"    {perm}: {status}")
                                    print(f"    Line {i+1}: {line.strip()}")
                except Exception:
                    pass

# 4. Check all dependency source manifests in pub cache
print("\n[4] DEPENDENCY MANIFESTS WITH READ_MEDIA")
print("-" * 40)
pub_cache = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Pub', 'Cache', 'hosted', 'pub.dev')
if os.path.exists(pub_cache):
    for pkg_dir in os.listdir(pub_cache):
        pkg_path = os.path.join(pub_cache, pkg_dir)
        if not os.path.isdir(pkg_path):
            continue
        for root, dirs, files in os.walk(pkg_path):
            # Skip example directories
            if 'example' in root:
                continue
            for f in files:
                if f == 'AndroidManifest.xml':
                    fpath = os.path.join(root, f)
                    try:
                        with open(fpath, 'r', encoding='utf-8') as fh:
                            content = fh.read()
                        for perm in ['READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO']:
                            if perm in content:
                                rel = os.path.relpath(fpath, pub_cache)
                                print(f"  {pkg_dir}: declares {perm}")
                                # Find the line
                                for line in content.split('\n'):
                                    if perm in line:
                                        print(f"    {line.strip()}")
                                break
                    except Exception:
                        pass

# 5. Check the actual merged manifest used for building
print("\n[5] FINAL PACKAGED MANIFEST")
print("-" * 40)
packaged = os.path.join(build_root, 'app', 'intermediates', 'packaged_manifests', 'release', 'processReleaseManifestForPackage', 'AndroidManifest.xml')
if os.path.exists(packaged):
    with open(packaged, 'r') as f:
        content = f.read()
    has_read_media = any(p in content for p in ['READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO'])
    print(f"  File exists: YES")
    print(f"  Contains READ_MEDIA_*: {'YES - PROBLEM!' if has_read_media else 'NO - Clean'}")
    if has_read_media:
        for line in content.split('\n'):
            if 'READ_MEDIA' in line:
                print(f"    {line.strip()}")
    # Also show all permissions
    print(f"\n  All permissions in final manifest:")
    for line in content.split('\n'):
        if 'uses-permission' in line.lower():
            print(f"    {line.strip()}")
else:
    print(f"  File not found at: {packaged}")

# 6. Use aapt2 to dump the compiled manifest if available
print("\n[6] AAPT2 DUMP (if available)")
print("-" * 40)
import subprocess
sdk_path = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'sdk')
aapt2_candidates = []
if os.path.exists(sdk_path):
    for root, dirs, files in os.walk(os.path.join(sdk_path, 'build-tools')):
        for f in files:
            if f.startswith('aapt2'):
                aapt2_candidates.append(os.path.join(root, f))

if aapt2_candidates:
    aapt2 = sorted(aapt2_candidates)[-1]  # latest version
    print(f"  Using aapt2: {aapt2}")
    try:
        # Extract manifest from AAB
        import tempfile
        with zipfile.ZipFile(aab, 'r') as z:
            manifest_data = z.read('base/manifest/AndroidManifest.xml')
            tmp = tempfile.NamedTemporaryFile(delete=False, suffix='.xml')
            tmp.write(manifest_data)
            tmp.close()
            
            result = subprocess.run(
                [aapt2, 'dump', 'xmltree', '--file', 'AndroidManifest.xml', aab.replace('.aab', '.aab')],
                capture_output=True, text=True, timeout=30
            )
            if result.returncode != 0:
                # Try bundletool or direct dump
                result = subprocess.run(
                    [aapt2, 'dump', 'badging', aab],
                    capture_output=True, text=True, timeout=30
                )
            
            output = result.stdout + result.stderr
            for line in output.split('\n'):
                if 'permission' in line.lower() or 'READ_MEDIA' in line:
                    print(f"    {line.strip()}")
            os.unlink(tmp.name)
    except Exception as e:
        print(f"  Error running aapt2: {e}")
else:
    print("  aapt2 not found")

print("\n" + "=" * 70)
print("ANALYSIS COMPLETE")
print("=" * 70)

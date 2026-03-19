import zipfile, struct

aab = r'C:\Dev\FlutterProjects\autogestion_max\build\app\outputs\bundle\release\app-release.aab'

with zipfile.ZipFile(aab, 'r') as z:
    for name in z.namelist():
        if not name.endswith('.so') or 'arm64' not in name:
            continue
        data = z.read(name)
        if data[:4] != b'\x7fELF':
            continue
        ei_class = data[4]
        if ei_class != 2:
            continue
        e_phoff = struct.unpack_from('<Q', data, 32)[0]
        e_phentsize = struct.unpack_from('<H', data, 54)[0]
        e_phnum = struct.unpack_from('<H', data, 56)[0]
        max_align = 0
        for i in range(e_phnum):
            ph_off = e_phoff + i * e_phentsize
            p_type = struct.unpack_from('<I', data, ph_off)[0]
            if p_type == 1:
                p_align = struct.unpack_from('<Q', data, ph_off + 48)[0]
                max_align = max(max_align, p_align)
        basename = name.split('/')[-1]
        status = '16KB OK' if max_align >= 16384 else f'NOT 16KB (align={max_align})'
        print(f'{basename}: max_load_align={max_align} -> {status}')

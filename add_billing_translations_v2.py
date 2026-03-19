#!/usr/bin/env python3
"""Add missing billing translation keys to all 12 language files."""
import os

base = r"c:\Dev\FlutterProjects\autogestion_max\lib\l10n\translations"

new_keys = {
    'es': {
        'notes_optional': 'Notas (opcional)',
        'mileage_hint': 'Ej. 45000 km',
        'notes_hint': 'Ej. Cambio de aceite, ticket #123',
        'photo_button_label': 'Foto',
    },
    'en': {
        'notes_optional': 'Notes (optional)',
        'mileage_hint': 'e.g. 45000 km',
        'notes_hint': 'e.g. Oil change, ticket #123',
        'photo_button_label': 'Photo',
    },
    'pt': {
        'notes_optional': 'Notas (opcional)',
        'mileage_hint': 'Ex. 45000 km',
        'notes_hint': 'Ex. Troca de óleo, ticket #123',
        'photo_button_label': 'Foto',
    },
    'fr': {
        'notes_optional': 'Notes (facultatif)',
        'mileage_hint': 'Ex. 45000 km',
        'notes_hint': 'Ex. Vidange, ticket #123',
        'photo_button_label': 'Photo',
    },
    'de': {
        'notes_optional': 'Notizen (optional)',
        'mileage_hint': 'z.B. 45000 km',
        'notes_hint': 'z.B. Ölwechsel, Ticket #123',
        'photo_button_label': 'Foto',
    },
    'it': {
        'notes_optional': 'Note (facoltativo)',
        'mileage_hint': 'Es. 45000 km',
        'notes_hint': 'Es. Cambio olio, scontrino #123',
        'photo_button_label': 'Foto',
    },
    'zh': {
        'notes_optional': '备注（可选）',
        'mileage_hint': '例如 45000 km',
        'notes_hint': '例如：机油更换，票据#123',
        'photo_button_label': '照片',
    },
    'ja': {
        'notes_optional': 'メモ（任意）',
        'mileage_hint': '例：45000 km',
        'notes_hint': '例：オイル交換、チケット#123',
        'photo_button_label': '写真',
    },
    'ar': {
        'notes_optional': 'ملاحظات (اختياري)',
        'mileage_hint': 'مثال: 45000 كم',
        'notes_hint': 'مثال: تغيير الزيت، تذكرة #123',
        'photo_button_label': 'صورة',
    },
    'ru': {
        'notes_optional': 'Заметки (необязательно)',
        'mileage_hint': 'Напр. 45000 км',
        'notes_hint': 'Напр. Замена масла, чек #123',
        'photo_button_label': 'Фото',
    },
    'hi': {
        'notes_optional': 'नोट्स (वैकल्पिक)',
        'mileage_hint': 'उदा. 45000 किमी',
        'notes_hint': 'उदा. तेल परिवर्तन, टिकट #123',
        'photo_button_label': 'फ़ोटो',
    },
    'ko': {
        'notes_optional': '메모 (선택사항)',
        'mileage_hint': '예: 45000 km',
        'notes_hint': '예: 오일 교환, 티켓 #123',
        'photo_button_label': '사진',
    },
}

anchor = "  'expenses_label':"

for lang, keys in new_keys.items():
    path = os.path.join(base, f"translations_{lang}.dart")
    if not os.path.exists(path):
        print(f"Not found: {path}")
        continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Skip if already added
    if "'notes_optional'" in content:
        print(f"Skipped (already has notes_optional): {lang}")
        continue

    # Find anchor line
    idx = content.find(anchor)
    if idx == -1:
        print(f"Anchor not found in {lang}")
        continue

    # Find the end of the anchor line (the closing of that entry's value and comma)
    end_of_anchor_line = content.index('\n', idx) + 1

    # Build new lines
    new_entries = ""
    for key, value in keys.items():
        escaped = value.replace("'", "\\'")
        new_entries += f"  '{key}': '{escaped}',\n"

    content = content[:end_of_anchor_line] + new_entries + content[end_of_anchor_line:]

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Updated: {lang}")

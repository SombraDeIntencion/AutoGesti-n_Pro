import re

# Función para extraer claves de un archivo dart
def extract_keys_from_dart_file(content):
    """Extrae todas las claves y valores de un archivo de traducción dart"""
    lines = content.split('\n')
    trans_dict = {}
    for line in lines:
        # Busca líneas del formato 'key': 'value',
        match = re.match(r"\s*'([^']+)':\s*'(.*)',?", line)
        if match:
            trans_dict[match.group(1)] = match.group(2)
    return trans_dict

# Lee los archivos
def read_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

# Archivos de traducción
files = {
    'ES': r'lib\l10n\translations\translations_es.dart',
    'EN': r'lib\l10n\translations\translations_en.dart',
    'PT': r'lib\l10n\translations\translations_pt.dart',
    'FR': r'lib\l10n\translations\translations_fr.dart',
    'DE': r'lib\l10n\translations\translations_de.dart',
    'IT': r'lib\l10n\translations\translations_it.dart',
    'ZH': r'lib\l10n\translations\translations_zh.dart',
    'JA': r'lib\l10n\translations\translations_ja.dart',
    'AR': r'lib\l10n\translations\translations_ar.dart',
    'RU': r'lib\l10n\translations\translations_ru.dart',
    'HI': r'lib\l10n\translations\translations_hi.dart',
    'KO': r'lib\l10n\translations\translations_ko.dart',
}

print("Analizando archivos de traducción...\n")

# Extraer claves de todos los archivos
translations = {}
for lang, path in files.items():
    try:
        content = read_file(path)
        translations[lang] = extract_keys_from_dart_file(content)
        print(f"✓ {lang}: {len(translations[lang])} claves")
    except Exception as e:
        print(f"✗ Error leyendo {lang}: {e}")

print()

# Referencia (español)
reference = translations['ES']
reference_keys = set(reference.keys())
total_keys = len(reference_keys)

print(f"Total de claves en español (referencia): {total_keys}\n")
print("="*90)

# Analizar cada idioma
results = []
for lang in ['EN', 'PT', 'FR', 'DE', 'IT', 'ZH', 'JA', 'AR', 'RU', 'HI', 'KO']:
    current = translations[lang]
    current_keys = set(current.keys())
    
    # Claves faltantes
    missing_keys = reference_keys - current_keys
    
    # Valores en inglés (comparando con inglés, excepto para EN)
    english_values_count = 0
    if lang != 'EN':
        english_translations = translations['EN']
        for key in current_keys:
            if key in english_translations and current.get(key) == english_translations.get(key):
                # El valor es igual al inglés, significa que no fue traducido
                english_values_count += 1
    
    # Estado
    status = 'COMPLETO' if len(missing_keys) == 0 and english_values_count == 0 else 'INCOMPLETO'
    
    results.append({
        'lang': lang,
        'total': len(current_keys),
        'missing': len(missing_keys),
        'english': english_values_count,
        'status': status,
        'missing_keys': sorted(list(missing_keys))
    })

# Resumen tabular
print("\nRESUMEN TABULAR DE TRADUCCIONES")
print("="*90)
print(f"{'Idioma':<8} {'Total Claves':<15} {'Faltantes':<13} {'En Inglés':<13} {'Estado':<15}")
print("-"*90)
for r in results:
    print(f"{r['lang']:<8} {r['total']}/{total_keys:<14} {r['missing']:<13} {r['english']:<13} {r['status']:<15}")
print("-"*90)

print(f"\n✅ Idiomas COMPLETOS: {sum(1 for r in results if r['status'] == 'COMPLETO')}")
print(f"⚠️  Idiomas INCOMPLETOS: {sum(1 for r in results if r['status'] == 'INCOMPLETO')}")

# Detalles de idiomas incompletos
print("\n" + "="*90)
print("DETALLES DE IDIOMAS INCOMPLETOS")
print("="*90)
for r in results:
    if r['status'] == 'INCOMPLETO':
        print(f"\n📋 {r['lang']} - {r['missing']} claves faltantes, {r['english']} valores en inglés")
        if r['missing'] > 0:
            print("  Primeras 15 claves faltantes:")
            for key in r['missing_keys'][:15]:
                print(f"    - '{key}'")
            if r['missing'] > 15:
                print(f"    ... y {r['missing'] - 15} más")

print("\n" + "="*90)
print("FIN DEL ANÁLISIS")
print("="*90)

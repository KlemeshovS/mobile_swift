#!/usr/bin/env python3
import json
import re
import sys

# Read the xcstrings file directly
with open('/Users/evgeniyvoynov/Documents/mobile_swift/Wobbly/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    xcstrings = json.load(f)

strings = xcstrings.get('strings', {})

# Patterns for achievement-related keys
ach_patterns = [
    r'^ach_',
    r'achievement',
    r'Achievement',
    r'condition_sport',
]

results = []

for key, value in strings.items():
    is_ach = any(re.search(p, key) for p in ach_patterns)
    if not is_ach:
        continue
    
    locs = value.get('localizations', {})
    en_val = ''
    ru_val = ''
    
    en_data = locs.get('en', {})
    if 'stringUnit' in en_data:
        en_val = en_data['stringUnit'].get('value', '')
    
    ru_data = locs.get('ru', {})
    if 'stringUnit' in ru_data:
        ru_val = ru_data['stringUnit'].get('value', '')
    
    results.append((key, en_val, ru_val))

results.sort(key=lambda x: x[0])

out = []
out.append(f"Total achievement-related keys: {len(results)}\n")
out.append(f"{'KEY':<55} | {'ENGLISH':<65} | RUSSIAN")
out.append("-" * 200)
for key, en, ru in results:
    out.append(f"{key:<55} | {en:<65} | {ru}")

result_text = "\n".join(out)

# Write result to the mobile_swift folder for access
with open('/Users/evgeniyvoynov/Documents/mobile_swift/achievement_keys_result.txt', 'w', encoding='utf-8') as f:
    f.write(result_text)

print("Done! Written to achievement_keys_result.txt")
print(f"Found {len(results)} keys")

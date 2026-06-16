#!/usr/bin/env python3
import json

with open('/Users/evgeniyvoynov/Documents/mobile_swift/Wobbly/Localizable.xcstrings', 'r') as f:
    data = json.load(f)

strings = data.get('strings', {})
ach_keys = sorted([k for k in strings.keys() if 'ach_' in k])

for key in ach_keys:
    entry = strings[key]
    locs = entry.get('localizations', {})
    
    en_val = ''
    ru_val = ''
    
    en = locs.get('en', {})
    ru = locs.get('ru', {})
    
    if 'stringUnit' in en:
        en_val = en['stringUnit'].get('value', '')
    if 'stringUnit' in ru:
        ru_val = ru['stringUnit'].get('value', '')
    
    print(f"{key} | {en_val} | {ru_val}")

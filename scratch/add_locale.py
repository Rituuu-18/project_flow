import re

with open('lib/core/localization/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

en_match = re.search(r"  'en': \{(.*?)\n  \},", content, flags=re.DOTALL)
if en_match:
    de_block = "\n  'de': {" + en_match.group(1) + "\n  },"
    new_content = content.replace('\n};', de_block + '\n};')
    
    with open('lib/core/localization/translations.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Added 'de' locale structure to translations.dart")
else:
    print("Could not find 'en' block")

import sys

with open('test_output.pdf', 'rb') as f:
    content = f.read().decode('latin-1')

print("PDF Objects containing /Link or /URI:")
for chunk in content.split('endobj'):
    if '/Link' in chunk or '/URI' in chunk:
        print("--- OBJ ---")
        print(chunk.strip())

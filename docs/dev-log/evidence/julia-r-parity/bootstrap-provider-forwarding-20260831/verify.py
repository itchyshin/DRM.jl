from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parent
manifest=json.loads((root/'manifest.json').read_text())
actual={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in root.rglob('*') if p.is_file() and p.name!='manifest.json'}
assert actual==manifest
print(f'ARTIFACT_INTEGRITY_PASS {len(actual)} files')

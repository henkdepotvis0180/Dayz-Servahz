"""Extract one Dutch changelog entry for a version tag, e.g. v0.6.0."""
import re
import sys
from pathlib import Path

if len(sys.argv) != 2 or not re.fullmatch(r"v\d+\.\d+\.\d+", sys.argv[1]):
    raise SystemExit("Usage: release_notes.py vMAJOR.MINOR.PATCH")

version = sys.argv[1][1:]
changelog = Path(__file__).resolve().parents[2] / "CHANGELOG.md"
source = changelog.read_text(encoding="utf-8")
matches = list(re.finditer(r"^## \[" + re.escape(version) + r"\] [^\n]+\n(.*?)(?=^## \[|\Z)", source, re.M | re.S))
if len(matches) != 1:
    raise SystemExit(f"Expected exactly one CHANGELOG entry for {version}")
print(matches[0].group(1).strip())
print("\n[Alle versies en update-instructies](https://github.com/henkdepotvis0180/Dayz-Servahz/blob/main/CHANGELOG.md)")

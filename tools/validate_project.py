#!/usr/bin/env python3
"""Lightweight repository validator for environments without the Godot binary.

Checks that scene/resource `res://` references point to files in the repository and
that the generated data libraries meet minimum expected counts.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RES_PATH_RE = re.compile(r'path="res://([^"]+)"')


def check_references() -> list[str]:
    errors: list[str] = []
    for path in ROOT.rglob("*"):
        if ".git" in path.parts or not path.is_file():
            continue
        if path.suffix not in {".tscn", ".tres", ".godot"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for match in RES_PATH_RE.finditer(text):
            target = ROOT / match.group(1)
            if not target.exists():
                errors.append(f"{path.relative_to(ROOT)} references missing res://{match.group(1)}")
    return errors


def check_counts() -> list[str]:
    errors: list[str] = []
    expectations = {
        "resources/signals/signals/*.tres": 150,
        "resources/upgrades/upgrades/*.tres": 12,
        "resources/achievements/achievements/*.tres": 25,
        "resources/emails/emails/*.tres": 35,
        "scenes/**/*.tscn": 50,
    }
    for pattern, minimum in expectations.items():
        count = len(list(ROOT.glob(pattern)))
        if count < minimum:
            errors.append(f"Expected at least {minimum} files matching {pattern}; found {count}")
    return errors


def main() -> int:
    errors = check_references() + check_counts()
    if errors:
        print("Validation failed:")
        for error in errors:
            print(f" - {error}")
        return 1
    print("Validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Fail when a relative Markdown link points to a missing local file."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote


LINK_PATTERN = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
IGNORED_PREFIXES = ("#", "http://", "https://", "mailto:")


def markdown_files(root: Path) -> list[Path]:
    return sorted(path for path in root.rglob("*.md") if ".git" not in path.parts)


def missing_links(root: Path) -> list[str]:
    failures: list[str] = []
    for document in markdown_files(root):
        content = document.read_text(encoding="utf-8")
        for match in LINK_PATTERN.finditer(content):
            raw_target = match.group(1).strip().strip("<>")
            if not raw_target or raw_target.startswith(IGNORED_PREFIXES):
                continue
            relative_target = unquote(raw_target.split("#", maxsplit=1)[0])
            target = (document.parent / relative_target).resolve()
            if not target.exists():
                line = content.count("\n", 0, match.start()) + 1
                failures.append(f"{document.relative_to(root)}:{line}: missing {raw_target}")
    return failures


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    failures = missing_links(root)
    if failures:
        print("Broken local Markdown links:", file=sys.stderr)
        print("\n".join(failures), file=sys.stderr)
        return 1
    print("All local Markdown links resolve.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

"""Validate this knowledge base using only Python's standard library.

Run from any directory: python docs/ai/validate_knowledge.py
This checks references and snapshot consistency, not Godot compilation/behavior.
Never refresh source hashes without reviewing the corresponding source changes.
"""
from pathlib import Path
from urllib.parse import unquote
import hashlib
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
KB = ROOT / "docs" / "ai"
SOURCE_DIRS = ("scripts", "tests", "scenes", "resources", "ui")
SOURCE_EXTENSIONS = {".gd", ".py", ".tscn", ".tres", ".gdshader"}


def source_symbols(text):
    patterns = (
        r"^\s*(?:static\s+)?func\s+(\w+)\s*\(",
        r"^\s*(?:async\s+)?def\s+(\w+)\s*\(",
        r"^\s*(?:class_name|class|signal|enum)\s+(\w+)",
        r"^\s*(?:@[^\n]*?\s+)?(?:var|const)\s+(\w+)",
    )
    return {m.group(1) for pattern in patterns for m in re.finditer(pattern, text, re.M)}


def main():
    inventory = json.loads((KB / "source-inventory.json").read_text(encoding="utf-8"))
    errors = []
    warnings = []
    indexed = {item["path"]: item for item in inventory["files"]}
    actual = {p.relative_to(ROOT).as_posix()
              for directory in SOURCE_DIRS
              for p in (ROOT / directory).rglob("*")
              if p.is_file() and p.suffix in SOURCE_EXTENSIONS}
    for missing in sorted(actual - indexed.keys()):
        errors.append(f"Source not indexed: {missing}")
    symbols_by_stem = {}
    for path, item in indexed.items():
        file = ROOT / path
        if not file.is_file():
            errors.append(f"Missing source: {path}")
            continue
        digest = hashlib.sha256(file.read_bytes()).hexdigest()
        if digest != item["sha256"]:
            errors.append(f"Source changed since review: {path}")
        if item["review"] not in ("full", "structured"):
            errors.append(f"Incomplete review: {path}")
        module = KB / "modules" / (item["module"] + ".md")
        if not module.is_file():
            errors.append(f"Missing module note for {path}: {module.name}")
        if file.suffix in (".gd", ".py"):
            symbols = source_symbols(file.read_text(encoding="utf-8-sig"))
            symbols_by_stem[file.stem] = symbols
            for symbol in item.get("symbols", []):
                if symbol["name"] not in symbols:
                    errors.append(f"Missing inventoried symbol: {path}:{symbol['name']}")

    docs = sorted(KB.rglob("*.md")) + [ROOT / "AGENTS.md", ROOT / "CLAUDE.md", ROOT / "docs/README.md"]
    source_names = {Path(path).name for path in indexed} | {Path(__file__).name}
    link_count = 0
    reference_count = 0
    symbol_count = 0
    for doc in docs:
        text = doc.read_text(encoding="utf-8")
        for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", text):
            target = target.strip().strip("<>")
            if re.match(r"^[a-zA-Z][\w+.-]*:", target) or target.startswith("#"):
                continue
            target = unquote(target.split("#", 1)[0])
            if not target:
                continue
            link_count += 1
            if not (doc.parent / target).exists():
                errors.append(f"Broken link in {doc.relative_to(ROOT)}: {target}")
        for token in re.findall(r"`([^`\n]+)`", text):
            if re.fullmatch(r"[A-Za-z_]\w*\.(?:gd|py|tscn|tres|gdshader)", token):
                reference_count += 1
                if token not in source_names:
                    errors.append(f"Unknown source filename in {doc.relative_to(ROOT)}: {token}")
            if re.fullmatch(r"(?:res://)?(?:scripts|tests|scenes|resources|ui|assets|docs)/[\w./-]+", token):
                reference_count += 1
                if not (ROOT / token.removeprefix("res://")).exists():
                    errors.append(f"Missing path in {doc.relative_to(ROOT)}: {token}")
        for owner, symbol in re.findall(r"\b([A-Z]\w*)\.(\w+)", text):
            if symbol in {"gd", "py", "tscn", "tres", "gdshader", "json", "md", "glb", "png"}:
                continue
            if owner in symbols_by_stem:
                symbol_count += 1
                if symbol not in symbols_by_stem[owner]:
                    errors.append(f"Unknown source symbol in {doc.relative_to(ROOT)}: {owner}.{symbol}")
        if "\ufffd" in text:
            errors.append(f"Invalid replacement character in {doc.relative_to(ROOT)}")

    if len(actual) != inventory["original_source_file_count"]:
        warnings.append("Source file count changed; review coverage totals.")
    for warning in warnings:
        print("WARNING:", warning)
    for error in errors:
        print("ERROR:", error)
    print(f"Checked {len(indexed)} source/config/data snapshots, {len(docs)} Markdown files, "
          f"{link_count} local links, {reference_count} source paths, {symbol_count} qualified symbols.")
    print(f"{len(errors)} errors, {len(warnings)} warnings. Runtime behavior is not checked.")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

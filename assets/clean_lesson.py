#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Typing-lesson cleaner

Stage 1: Normalize non-keyboard punctuation to ASCII equivalents.
 - Curly quotes -> straight
 - En/em dashes & minus sign -> hyphen-minus
 - Ellipsis -> "..."
 - Full-width punctuation -> ASCII
 - NO-BREAK / thin spaces -> normal space
 - Zero-width characters -> removed
 - Special rule: for Units 1–24, map back-tick ` -> single quote '.
                 for Units >=25, keep back-tick as is.

Stage 2: Enforce per-unit allowed characters (hardcoded in this file).
 - Any character not in the allowed set for that unit (plus whitespace)
   is replaced with a randomly chosen character from that unit's allowed set.
 - Whitespace characters are always preserved.

Inputs:
 - UNITS_JSON variable below (paste your units.json here) OR
 - "units.json" located in the **same directory as this script**.

Outputs:
 - Prints cleaned JSON to stdout
 - Writes "clean_units.json" **in the same directory as this script**
 - Prints a summary of forbidden characters replaced per unit/subunit
"""

from __future__ import annotations

import json
import os
import secrets
import sys
from collections import defaultdict
from typing import Dict, List, Union, Tuple, Set, Any, Iterable

# ===================== USER-PASTE AREA =====================
# If you prefer, paste the *entire* JSON object from units.json here.
# Leave as None to read "units.json" next to this script.
UNITS_JSON: Union[dict, list, None] = None
# =================== END USER-PASTE AREA ===================


# ---------------- HARD-CODED CHAR RULES --------------------
# NOTE: Whitespace (space, tab, CR, LF, etc.) is always allowed and
# is NOT included in these sets. Stage 2 always preserves whitespace.
ALL_UNITS_ALLOWED: Set[str] = set(
    "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!#$%&'()*+,-./;=@^_`~"
)

# Per-unit cumulative allowed characters (1-based unit index)
PER_UNIT_ALLOWED: Dict[int, Set[str]] = {
    1: set("adfjkls;"),
    2: set("adfjklrsu;"),
    3: set("adfjklmrsuv;"),
    4: set("adefijklmrsuv;"),
    5: set("acdefijklmrsuv,;"),
    6: set("acdefghijklmrsuv,;"),
    7: set("acdefghijklmrstuvy,;"),
    8: set("abcdefghijklmnrstuvy,;"),
    9: set("abcdefghijklmnorstuvwy,;"),
    10: set("abcdefghijklmnorstuvwxy,.;"),
    11: set("abcdefghijklmnopqrstuvwxy,.;"),
    12: set("abcdefghijklmnopqrstuvwxyz,./;"),
    13: set("abcdefghijklmnopqrstuvwxyz',./;"),
    14: set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',./;"),
    15: set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',./;"),
    16: set("58abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',./;"),
    17: set("4589abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',./;"),
    18: set("456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',./;"),
    19: set("03456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',./;"),
    20: set("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',./;"),
    21: set("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',./;"),
    22: set("!#$@0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',./;"),
    23: set("!#$&*()@0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',./;"),
    24: set("!#$&*()@0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',./;"),
    # Display note in the original spec mentioned brackets/braces in order text,
    # but ALL_UNITS_ALLOWED is the source of truth. Stage 2 enforces conformity.
    25: set("!#$%&()*+-./0123456789:=@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{}~',;"),
    26: ALL_UNITS_ALLOWED,
    27: ALL_UNITS_ALLOWED,
}
# -----------------------------------------------------------


# ---------- Stage 1: Unicode → ASCII normalization ----------
# Single-character normalizations (and deletions)
NONKEYBOARD_MAP_SINGLE: Dict[str, str] = {
    # Curly / typographic quotes -> straight
    "\u2019": "'",  # ’
    "\u2018": "'",  # ‘
    "\u2032": "'",  # ′
    "\u02BC": "'",  # ʼ
    "\u00B4": "'",  # ´
    "\uFF07": "'",  # fullwidth '
    "\u201C": '"',  # “
    "\u201D": '"',  # ”
    "\u2033": '"',  # ″
    "\uFF02": '"',  # fullwidth "
    # Dashes / minus variants -> hyphen-minus
    "\u2013": "-",  # –
    "\u2014": "-",  # —
    "\u2212": "-",  # −
    "\u2011": "-",  # non-breaking hyphen
    "\uFF0D": "-",  # fullwidth -
    # Spaces -> normal space
    "\u00A0": " ",  # NO-BREAK SPACE
    "\u2009": " ",  # thin spaces & friends…
    "\u200A": " ",
    "\u2008": " ",
    "\u2007": " ",
    "\u2006": " ",
    "\u2005": " ",
    "\u2004": " ",
    "\u2003": " ",
    "\u2002": " ",
    "\u2001": " ",
    "\u2000": " ",
    # Zero-width / format chars -> remove
    "\u200B": "",   # zero width space
    "\uFEFF": "",   # zero width no-break space
    "\u2060": "",   # word joiner
    # Full-width punctuations -> ASCII
    "\uFF01": "!", "\uFF03": "#", "\uFF04": "$", "\uFF05": "%", "\uFF06": "&",
    "\uFF08": "(", "\uFF09": ")", "\uFF0A": "*", "\uFF0B": "+", "\uFF0C": ",",
    "\uFF0E": ".", "\uFF0F": "/", "\uFF1A": ":", "\uFF1B": ";", "\uFF1D": "=",
    "\uFF20": "@", "\uFF3B": "[", "\uFF3D": "]", "\uFF5B": "{", "\uFF5D": "}",
    "\uFF40": "`", "\uFF3E": "^", "\uFF3C": "\\", "\uFF3F": "_", "\uFF5E": "~",
}
ELLIPSIS = "\u2026"  # …


def normalize_text(raw: str, unit_index: int) -> str:
    """Normalize typographic and full-width punctuation to ASCII (Stage 1)."""
    if not raw:
        return raw
    text = raw.replace(ELLIPSIS, "...")  # multi-character expansion first
    for src, dst in NONKEYBOARD_MAP_SINGLE.items():
        if src in text:
            text = text.replace(src, dst)
    # Special back-tick rule
    if unit_index <= 24:
        text = text.replace("`", "'")
    return text


# -------------------- Utility helpers ----------------------
def script_directory() -> str:
    """
    Return the absolute directory path where this script resides.
    Works when:
      - Run directly (python path/to/script.py)
      - Run via relative/absolute path from any cwd
      - The script path is a symlink
    Falls back to current working directory if __file__ is unavailable.
    """
    try:
        return os.path.dirname(os.path.realpath(__file__))
    except NameError:
        # __file__ may not exist in some interactive contexts
        return os.getcwd()


def load_units_json(in_memory_json: Union[dict, list, None], units_path: str) -> Union[dict, list]:
    """
    Load units JSON either from the in-memory variable (if provided) or from disk.
    """
    if in_memory_json is not None:
        return in_memory_json
    if not os.path.exists(units_path):
        raise FileNotFoundError(
            f"Could not find 'units.json' at: {units_path}\n"
            "Place 'units.json' next to this script, or paste JSON into UNITS_JSON at the top."
        )
    with open(units_path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def iter_units_list(units_root: Union[dict, list]) -> List[dict]:
    """
    Return a list of unit dicts from either a top-level list or a dict with {'main': [...]}
    or a single-unit dict shape {'title': ..., 'subunits': {...}}.
    """
    if isinstance(units_root, list):
        return units_root
    if isinstance(units_root, dict):
        if "main" in units_root and isinstance(units_root["main"], list):
            return units_root["main"]
        if "title" in units_root and "subunits" in units_root:
            return [units_root]
    raise ValueError("UNITS_JSON must be a list of units or a dict with key 'main' -> list of units.")


# ---------------- Stage 2: Policy enforcement ---------------
def replace_forbidden_chars(
    text: str,
    allowed: Set[str],
    summary: Dict[int, Dict[str, List[Tuple[str, str]]]],
    unit_idx: int,
    subunit_name: str
) -> str:
    """
    Replace any non-whitespace character not in the allowed set
    with a random character from the allowed set. Record replacements.
    """
    if not text or not allowed:
        return text

    out_chars: List[str] = []
    allowed_tuple = tuple(allowed)  # speed up random choice
    for ch in text:
        if ch.isspace() or (ch in allowed):
            out_chars.append(ch)
        else:
            repl = secrets.choice(allowed_tuple)
            out_chars.append(repl)
            summary[unit_idx][subunit_name].append((ch, repl))
    return "".join(out_chars)


def walk_and_clean(
    obj: Any,
    unit_idx: int,
    allowed: Set[str],
    summary: Dict[int, Dict[str, List[Tuple[str, str]]]],
    current_subunit_name: str
) -> Any:
    """
    Recursively walk subunit content and clean all string leaves.
    Preserves non-string structures (dict/list) but cleans their string leaves.
    """
    if isinstance(obj, str):
        return replace_forbidden_chars(normalize_text(obj, unit_idx), allowed, summary, unit_idx, current_subunit_name)
    if isinstance(obj, list):
        return [walk_and_clean(x, unit_idx, allowed, summary, current_subunit_name) for x in obj]
    if isinstance(obj, dict):
        return {k: walk_and_clean(v, unit_idx, allowed, summary, current_subunit_name) for k, v in obj.items()}
    return obj


def clean_units(
    units_root: Union[dict, list],
    per_unit_allowed: Dict[int, Set[str]]
) -> Tuple[Union[dict, list], Dict[int, Dict[str, List[Tuple[str, str]]]]]:
    """
    Apply Stage 1 & 2 cleaning to all string leaves under each unit's 'subunits' only.
    Returns (cleaned_units_root, summary).
    """
    units = iter_units_list(units_root)
    cleaned_units: List[dict] = []
    summary: Dict[int, Dict[str, List[Tuple[str, str]]]] = defaultdict(lambda: defaultdict(list))

    max_defined_unit = max(per_unit_allowed.keys())

    for unit_idx, unit in enumerate(units, start=1):
        allowed_set = per_unit_allowed.get(unit_idx, per_unit_allowed[max_defined_unit])
        new_unit: Dict[str, Any] = {}

        for key, value in unit.items():
            if key != "subunits":
                new_unit[key] = value
                continue

            # Clean only the 'subunits' branch; support nested structures
            if not isinstance(value, dict):
                new_unit[key] = value
                continue

            new_subunits: Dict[str, Any] = {}
            for sub_name, sub_val in value.items():
                new_subunits[sub_name] = walk_and_clean(sub_val, unit_idx, allowed_set, summary, sub_name)

            new_unit[key] = new_subunits

        cleaned_units.append(new_unit)

    # Return in the original container shape
    if isinstance(units_root, list):
        return cleaned_units, summary
    if isinstance(units_root, dict):
        if "main" in units_root and isinstance(units_root["main"], list):
            out = dict(units_root)
            out["main"] = cleaned_units
            return out, summary
        else:
            # Single-unit dict case
            return cleaned_units[0], summary
    return cleaned_units, summary


# --------------------------- Main ---------------------------
def main() -> None:
    # Resolve paths relative to the script location (not the caller's cwd)
    script_dir = script_directory()
    units_path = os.path.join(script_dir, "units.json")
    output_path = os.path.join(script_dir, "clean_units.json")

    # Load input JSON
    try:
        root = load_units_json(UNITS_JSON, units_path)
    except FileNotFoundError as e:
        sys.stderr.write(f"[ERROR] {e}\n")
        sys.exit(1)

    # Clean and summarize
    cleaned_root, summary = clean_units(root, PER_UNIT_ALLOWED)

    # Write output JSON next to the script
    try:
        with open(output_path, "w", encoding="utf-8") as out_f:
            json.dump(cleaned_root, out_f, ensure_ascii=False, indent=2)
    except OSError as e:
        sys.stderr.write(f"[ERROR] Failed to write output to {output_path}: {e}\n")
        sys.exit(1)

    # Also print cleaned JSON to stdout (so it can be piped/inspected)
    json.dump(cleaned_root, sys.stdout, ensure_ascii=False, indent=2)
    print()  # trailing newline

    # Human-friendly summary
    print("\n=== SUMMARY OF REPLACEMENTS ===")
    if not summary:
        print("No forbidden characters found. Nothing was replaced.")
    else:
        for unit_index in sorted(summary.keys()):
            print(f"Unit {unit_index}:")
            for subunit_name, pairs in summary[unit_index].items():
                if not pairs:
                    continue
                print(f"  Subunit '{subunit_name}': {len(pairs)} forbidden chars replaced")
                # Show first 10 examples
                for ch, rep in pairs[:10]:
                    # Render control/space visibly in preview lines
                    ch_disp = ch if not ch.isspace() else repr(ch)
                    rep_disp = rep if not rep.isspace() else repr(rep)
                    print(f"    {ch_disp} -> {rep_disp}")
                if len(pairs) > 10:
                    print(f"    ... and {len(pairs) - 10} more")
        print(f"\nSaved cleaned JSON to: {output_path}")
        print(f"Read input JSON from:  {units_path if UNITS_JSON is None else 'UNITS_JSON (in-memory variable)'}")


if __name__ == "__main__":
    main()

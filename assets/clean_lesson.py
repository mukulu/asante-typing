#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Typing-lesson cleaner

Stage 1: Normalize non-keyboard punctuation to ASCII equivalents.
Stage 2: Enforce per-unit allowed characters (hardcoded rules).
"""

import json, os, secrets, sys
from typing import Dict, List, Union, Tuple, Set
from collections import defaultdict

# ===================== USER-PASTE AREA =====================
UNITS_JSON: Union[dict, list, None] = None
# =================== END USER-PASTE AREA ===================

OUTPUT_PATH = "clean_units.json"

# ---------------- HARD-CODED CHAR RULES --------------------
ALL_UNITS_ALLOWED: Set[str] = set("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!#$%&'()*+,-./;=@^_`~")

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
    25: set("!#$%&()*+-./0123456789:=@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{}~',;"),
    26: ALL_UNITS_ALLOWED,
    27: ALL_UNITS_ALLOWED,
}
# ------------------------------------------------------------

# Stage 1 mapping
NONKEYBOARD_MAP_SINGLE = {
    "\u2019": "'", "\u2018": "'", "\u2032": "'", "\u02BC": "'", "\u00B4": "'",
    "\uFF07": "'", "\u201C": '"', "\u201D": '"', "\u2033": '"', "\uFF02": '"',
    "\u2013": "-", "\u2014": "-", "\u2212": "-", "\u2011": "-", "\uFF0D": "-",
    "\u00A0": " ", "\u2009": " ", "\u200A": " ", "\u2008": " ", "\u2007": " ",
    "\u2006": " ", "\u2005": " ", "\u2004": " ", "\u2003": " ", "\u2002": " ",
    "\u2001": " ", "\u2000": " ",
    "\u200B": "", "\uFEFF": "", "\u2060": "",
    "\uFF01": "!", "\uFF03": "#", "\uFF04": "$", "\uFF05": "%", "\uFF06": "&",
    "\uFF08": "(", "\uFF09": ")", "\uFF0A": "*", "\uFF0B": "+", "\uFF0C": ",",
    "\uFF0E": ".", "\uFF0F": "/", "\uFF1A": ":", "\uFF1B": ";", "\uFF1D": "=",
    "\uFF20": "@", "\uFF3B": "[", "\uFF3D": "]", "\uFF5B": "{", "\uFF5D": "}",
    "\uFF40": "`", "\uFF3E": "^", "\uFF3C": "\\", "\uFF3F": "_", "\uFF5E": "~",
}
ELLIPSIS = "\u2026"

def normalize_text(raw: str, unit_index: int) -> str:
    if not raw: return raw
    text = raw.replace(ELLIPSIS, "...")
    for src, dst in NONKEYBOARD_MAP_SINGLE.items():
        if src in text:
            text = text.replace(src, dst)
    if unit_index <= 24:
        text = text.replace("`", "'")
    return text

def iter_units_list(units_root: Union[dict, list]) -> List[dict]:
    if isinstance(units_root, list):
        return units_root
    if isinstance(units_root, dict):
        if "main" in units_root: return units_root["main"]
        if "title" in units_root and "subunits" in units_root: return [units_root]
    raise ValueError("Invalid UNITS_JSON shape")

def replace_forbidden_chars(text: str, allowed: Set[str], summary: dict, unit_idx: int, subunit: str) -> str:
    out = []
    for ch in text:
        if ch.isspace() or ch in allowed:
            out.append(ch)
        else:
            replacement = secrets.choice(tuple(allowed)) if allowed else ch
            out.append(replacement)
            summary[unit_idx][subunit].append((ch, replacement))
    return "".join(out)

def clean_units(units_root: Union[dict, list], per_unit_allowed: Dict[int, Set[str]]) -> Tuple[Union[dict, list], dict]:
    units = iter_units_list(units_root)
    cleaned_units, summary = [], defaultdict(lambda: defaultdict(list))
    for unit_idx, unit in enumerate(units, start=1):
        allowed = per_unit_allowed.get(unit_idx, per_unit_allowed[max(per_unit_allowed)])
        new_unit = {}
        for k, v in unit.items():
            if k != "subunits": new_unit[k] = v; continue
            new_sub = {}
            for sub_name, sub_val in v.items():
                if isinstance(sub_val, str):
                    t1 = normalize_text(sub_val, unit_idx)
                    t2 = replace_forbidden_chars(t1, allowed, summary, unit_idx, sub_name)
                    new_sub[sub_name] = t2
                else:
                    new_sub[sub_name] = sub_val
            new_unit[k] = new_sub
        cleaned_units.append(new_unit)
    if isinstance(units_root, list): return cleaned_units, summary
    if isinstance(units_root, dict) and "main" in units_root:
        out = dict(units_root); out["main"] = cleaned_units; return out, summary
    return cleaned_units[0], summary

def main():
    root = UNITS_JSON
    if root is None:
        with open("units.json","r",encoding="utf-8") as fh:
            root = json.load(fh)
    cleaned, summary = clean_units(root, PER_UNIT_ALLOWED)
    with open(OUTPUT_PATH,"w",encoding="utf-8") as out_f:
        json.dump(cleaned,out_f,ensure_ascii=False,indent=2)
    json.dump(cleaned, sys.stdout, ensure_ascii=False, indent=2); print()
    print("\n=== SUMMARY OF REPLACEMENTS ===")
    for unit, subs in summary.items():
        print(f"Unit {unit}:")
        for sub, repls in subs.items():
            if repls:
                print(f"  Subunit '{sub}': {len(repls)} forbidden chars replaced")
                for ch, rep in repls[:10]:
                    print(f"    '{ch}' -> '{rep}'")
                if len(repls) > 10:
                    print(f"    ... and {len(repls)-10} more")

if __name__=="__main__":
    main()

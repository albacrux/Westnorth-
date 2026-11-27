#!/usr/bin/env python3
# Westnorth: apply the fork's pt-BR translations to po/<domain>/pt_BR.po.
#
# Each file in utils/westnorth/translations/<domain>-*.py defines a dict T
# (files named <domain>-new.py hold strings the fork added; missing ones are appended)
# {msgid: msgstr} (plural entries: msgid -> [singular, plural]). Matching entries
# get the new msgstr and lose the "fuzzy" flag; unknown msgids are reported.
# Re-run after cherry-picking upstream translation updates.
#
# Usage: utils/westnorth/apply_translations.py [--check]
#   --check  exit 1 if a translation file mentions a msgid that is not in the .po
import glob
import os
import runpy
import sys

import polib  # pip install polib

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def entry_spans(lines):
    """Map every line number (1-based) -> (start, end) line indexes of its entry block."""
    spans = {}
    i = 0
    n = len(lines)
    while i < n:
        if lines[i].strip() == "":
            i += 1
            continue
        start = i
        while i < n and lines[i].strip() != "":
            i += 1
        for j in range(start, i):
            spans[j + 1] = (start, i)
    return spans


def main():
    check_only = "--check" in sys.argv
    missing = 0
    for path in sorted(glob.glob(os.path.join(ROOT, "utils/westnorth/translations/*.py"))):
        domain = os.path.basename(path).rsplit("-", 1)[0]
        po_path = os.path.join(ROOT, "po", domain, "pt_BR.po")
        if not os.path.isfile(po_path):
            print(f"{os.path.basename(path)}: no {po_path}; name files <domain>-<anything>.py")
            missing += 1
            continue
        table = runpy.run_path(path)["T"]
        po = polib.pofile(po_path, wrapwidth=79)
        by_id = {e.msgid: e for e in po if not e.obsolete}
        with open(po_path, encoding="utf-8") as f:
            lines = f.read().split("\n")
        spans = entry_spans(lines)
        replacements = {}
        appended = 0
        for msgid, msgstr in table.items():
            entry = by_id.get(msgid)
            if entry is None and path.endswith("-new.py"):
                # Strings that only exist in the fork: append them to the .po.
                entry = polib.POEntry(msgid=msgid, msgstr=msgstr,
                                      comment="Westnorth: string added by the fork")
                lines.extend(entry.__unicode__(wrapwidth=79).split("\n"))
                by_id[msgid] = entry
                appended += 1
                continue
            if entry is None:
                print(f"{os.path.basename(path)}: msgid not in {domain}: {msgid[:60]!r}")
                missing += 1
                continue
            if isinstance(msgstr, list):
                entry.msgstr_plural = {i: s for i, s in enumerate(msgstr)}
            else:
                entry.msgstr = msgstr
            if "fuzzy" in entry.flags:
                entry.flags.remove("fuzzy")
            # A literal "50% de" reads as a printf spec; these strings are not printf'd.
            if "c-format" in entry.flags and "%" in "".join([entry.msgstr] + list(entry.msgstr_plural.values())):
                entry.flags[entry.flags.index("c-format")] = "no-c-format"
            entry.previous_msgid = None
            entry.previous_msgid_plural = None
            entry.previous_msgctxt = None
            replacements[spans[entry.linenum]] = entry.__unicode__(wrapwidth=79).rstrip("\n").split("\n")
        # Replace blocks from the end so earlier indexes stay valid: only the
        # touched entries change, the rest of the file keeps upstream's layout.
        for (start, end) in sorted(replacements, reverse=True):
            lines[start:end] = replacements[(start, end)]
        if not check_only:
            with open(po_path, "w", encoding="utf-8") as f:
                f.write("\n".join(lines))
        print(f"{domain}: {len(replacements)} updated, {appended} added from {os.path.basename(path)}")
    return 1 if (missing and check_only) else 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""
Simple site tests for a static HTML file.

Checks performed:
- <title> exists and non-empty
- meta viewport present
- <html> has lang attribute
- <link rel="canonical"> present
- all <img> tags have non-empty alt attributes
- internal anchor hrefs (href="#id") point to existing id attributes

Usage: python tools\site_test.py [path/to/index.html]
"""
import re
import sys
from pathlib import Path


def load_file(path: Path) -> str:
    try:
        return path.read_text(encoding='utf-8')
    except Exception as e:
        print(f"ERROR: Could not read {path}: {e}")
        sys.exit(2)


def find_tag(regex, text):
    return re.search(regex, text, re.I | re.S)


def find_all(regex, text):
    return re.findall(regex, text, re.I | re.S)


def main():
    p = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent.parent / 'index.html'
    if not p.exists():
        print(f"ERROR: File not found: {p}")
        sys.exit(2)

    text = load_file(p)
    failures = []

    # Title
    title_m = find_tag(r'<title\s*>(.*?)</title>', text)
    if not title_m or not title_m.group(1).strip():
        failures.append('Missing or empty <title>')
    else:
        print(f"Title: {title_m.group(1).strip()}")

    # Meta viewport
    if not find_tag(r'<meta[^>]+name=[\"\']viewport[\"\']', text):
        failures.append('Missing meta viewport')

    # html lang
    html_lang = find_tag(r'<html[^>]+lang=[\"\']([^\"\']+)[\"\']', text)
    if not html_lang:
        failures.append('Missing lang attribute on <html>')
    else:
        print(f"HTML lang: {html_lang.group(1)}")

    # canonical
    if not find_tag(r'<link[^>]+rel=[\"\']canonical[\"\']', text):
        failures.append('Missing <link rel="canonical">')

    # Images alt
    img_tags = find_all(r'<img\b[^>]*>', text)
    img_no_alt = []
    img_empty_alt = []
    for img in img_tags:
        alt_m = re.search(r'alt\s*=\s*(["\'])(.*?)\1', img, re.I | re.S)
        if not alt_m:
            img_no_alt.append(img)
        elif not alt_m.group(2).strip():
            img_empty_alt.append(img)
    if img_no_alt:
        failures.append(f"{len(img_no_alt)} <img> tag(s) missing alt attribute")
    if img_empty_alt:
        failures.append(f"{len(img_empty_alt)} <img> tag(s) with empty alt")

    # Internal links (href="#id") -> check matching id
    internal_targets = find_all(r'href\s*=\s*["\']#([^"\']+)["\']', text)
    ids = set(find_all(r'id\s*=\s*["\']([^"\']+)["\']', text))
    broken_anchors = [t for t in internal_targets if t not in ids]
    if broken_anchors:
        failures.append(f"{len(broken_anchors)} internal link(s) target missing id: {', '.join(broken_anchors)}")

    # Summary
    print('\nChecks run: title, viewport, lang, canonical, img alt, internal links')
    if failures:
        print('\nFAILURES:')
        for f in failures:
            print(f" - {f}")
        print('\nResult: FAIL')
        sys.exit(1)
    else:
        print('\nResult: PASS')
        sys.exit(0)


if __name__ == '__main__':
    main()

import glob
import re
import sys

def strip_swift_comments_and_strings(source: str):
    res = []
    i = 0
    n = len(source)
    while i < n:
        # Multi-line comment
        if source[i:i+2] == '/*':
            i = i + 2
            depth = 1
            while i < n and depth > 0:
                if source[i:i+2] == '/*':
                    depth += 1
                    i += 2
                elif source[i:i+2] == '*/':
                    depth -= 1
                    i += 2
                else:
                    i += 1
            continue
        # Single-line comment
        if source[i:i+2] == '//':
            i += 2
            while i < n and source[i] != '\n':
                i += 1
            continue
        # Multi-line string
        if source[i:i+3] == '"""':
            i = i + 3
            while i < n:
                if source[i:i+3] == '"""':
                    i = i + 3
                    break
                elif source[i:i+1] == '\\' and i + 1 < n:
                    i += 2
                else:
                    i += 1
            continue
        # Single-line string
        if source[i] == '"':
            i += 1
            while i < n:
                if source[i] == '"':
                    i += 1
                    break
                elif source[i:i+1] == '\\' and i + 1 < n:
                    i += 2
                else:
                    i += 1
            continue
        # Normal character
        res.append(source[i])
        i += 1
    return "".join(res)

def strip_swift_comments_only(source: str):
    """Remove comments but KEEP string literals, so Color(hex: "...") stays scannable."""
    res = []
    i = 0
    n = len(source)
    while i < n:
        if source[i:i+2] == '/*':
            i = i + 2
            depth = 1
            while i < n and depth > 0:
                if source[i:i+2] == '/*':
                    depth += 1
                    i += 2
                elif source[i:i+2] == '*/':
                    depth -= 1
                    i += 2
                else:
                    i += 1
            continue
        if source[i:i+2] == '//':
            i += 2
            while i < n and source[i] != '\n':
                i += 1
            continue
        # keep strings verbatim (including their quotes)
        if source[i] == '"':
            triple = source[i:i+3] == '"""'
            res.append(source[i])
            i += 3 if triple else 1
            while i < n:
                res.append(source[i])
                if source[i:i+1] == '\\' and i + 1 < n:
                    res.append(source[i+1])
                    i += 2
                    continue
                if triple:
                    if source[i:i+3] == '"""':
                        res.append('""')
                        i += 3
                        break
                elif source[i] == '"':
                    i += 1
                    break
                i += 1
            continue
        res.append(source[i])
        i += 1
    return "".join(res)

def validate_brackets(clean_code: str):
    stack = []
    pairs = {')': '(', '}': '{', ']': '['}
    for idx, c in enumerate(clean_code):
        if c in '({[':
            stack.append((c, idx))
        elif c in ')}]':
            if not stack:
                return f"Unexpected closing '{c}' at position {idx}"
            top, top_idx = stack.pop()
            if top != pairs[c]:
                return f"Mismatched opening '{top}' at {top_idx} with closing '{c}' at {idx}"
    if stack:
        top, top_idx = stack[-1]
        return f"Unclosed '{top}' from position {top_idx}"
    return None

# ---------------------------------------------------------------------------
# Brand hex-literal lint (R-1 guard, Sept 1 visual release audit)
# Raw Color(hex: "...") literals are only allowed:
#   - inside the DesignSystem directory (token definitions),
#   - in locked canonical navigation components whose material hexes are part
#     of the approved locked reference (Image 40),
#   - as platform-brand identity colors (gig-platform brand hexes used for
#     third-party recognition),
#   - as Tree of Life warm metallic growth light (approved experience ref).
# Everything else must use MilliColors / MilliBlueprint tokens.
# ---------------------------------------------------------------------------
ALLOWED_DIRS = ('MilliTaxVault/DesignSystem',)
LOCKED_NAV_FILES = (
    'MilliTaxVault/Components/MilliNavBar.swift',
    'MilliTaxVault/Components/MilliCenterMButton.swift',
    'MilliTaxVault/Components/BelAirNavBarShape.swift',
)
EXPERIENCE_HEXES = {
    '7D5E48',  # warm bronze growth light
    'D0B69D',  # warm metallic highlight
}
PLATFORM_BRAND_HEXES = {
    'FF00BF',  # Lyft
    'FF3008',  # DoorDash
    '0071DC',  # Spark / Walmart
    'FF9900',  # Amazon
    '000000',  # Uber black
    '4285F4',  # Google blue
    '34C759',  # Apple system green (sign-in)
    '16844A',  # Instacart green
    'C44724',  # platform identity
    '3276D9',  # platform identity
    '4E8CFF',  # platform identity
}
HEX_RE = re.compile(r'Color\(hex:\s*"([0-9A-Fa-f]{6})"\)')

def validate_brand_hex_literals():
    errors = 0
    for f in sorted(glob.glob('MilliTaxVault/**/*.swift', recursive=True)):
        if f.startswith(ALLOWED_DIRS) or f in LOCKED_NAV_FILES:
            continue
        content = open(f).read()
        # strip comments but KEEP strings so Color(hex:) literals are scannable
        clean = strip_swift_comments_only(content)
        for m in HEX_RE.finditer(clean):
            hexv = m.group(1).upper()
            if hexv in PLATFORM_BRAND_HEXES or hexv in EXPERIENCE_HEXES:
                continue
            line = clean[:m.start()].count('\n') + 1
            print(f"❌ {f}:{line}: off-token Color(hex: \"{m.group(1)}\") — use MilliColors tokens")
            errors += 1
    return errors

swift_files = sorted(glob.glob('MilliTaxVault/**/*.swift', recursive=True))
print(f"Scanning {len(swift_files)} Swift source files...")

errors = 0
for f in swift_files:
    content = open(f).read()
    clean = strip_swift_comments_and_strings(content)
    err = validate_brackets(clean)
    if err:
        print(f"❌ {f}: {err}")
        errors += 1

hex_errors = validate_brand_hex_literals()
if hex_errors:
    print(f"❌ Brand hex-literal lint: {hex_errors} violation(s).")
    errors += hex_errors

if errors == 0:
    print(f"✅ All {len(swift_files)} Swift files passed lexical syntax validation and brand hex-literal lint with ZERO errors!")
else:
    print(f"❌ Found {errors} error(s).")
    sys.exit(1)

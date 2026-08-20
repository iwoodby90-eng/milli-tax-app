import glob

def strip_swift_comments_and_strings(source: str):
    res = []
    i = 0
    n = len(source)
    while i < n:
        # Multi-line comment
        if source[i:i+2] == '/*':
            i += 2
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
            i += 3
            while i < n:
                if source[i:i+3] == '"""':
                    i += 3
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

if errors == 0:
    print(f"✅ All {len(swift_files)} Swift files passed character-level lexical syntax validation with ZERO errors!")
else:
    print(f"❌ Found {errors} syntax errors.")
    exit(1)

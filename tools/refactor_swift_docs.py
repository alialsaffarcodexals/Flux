#!/usr/bin/env python3
import os
import re
import argparse

# Regex to find simple declarations and function names
SIMPLE_DECL_RE = re.compile(r"\b(class|struct|enum|extension)\s+([A-Za-z0-9_]+)")
FUNC_RE = re.compile(r"\bfunc\s+([A-Za-z0-9_]+)\s*\(([^)]*)\)\s*(?:->\s*([^\s{]+))?")

def remove_comments(text: str) -> str:
    # remove block comments
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    # remove line comments
    text = re.sub(r'//.*', '', text)
    return text


def extract_decls(lines):
    decls = []
    i = 0
    n = len(lines)
    while i < n:
        # skip whitespace
        if lines[i].strip().startswith('@'):
            # attribute block
            j = i
            while j < n and lines[j].strip().startswith('@'):
                j += 1
            if j < n and is_declaration_line(lines[j]):
                decls.append((i, j))
                i = j + 1
                continue
            else:
                i = j
                continue
        if is_declaration_line(lines[i]):
            decls.append((i, i))
            i += 1
            continue
        i += 1
    return decls


def is_declaration_line(line: str) -> bool:
    s = line.strip()
    if not s:
        return False
    # match declarations that start with optional modifiers then a declaration keyword
    return re.match(r'^(?:@\w+\b\s*)*(?:public|private|fileprivate|internal|open|final|static|override|convenience|required|mutating|nonmutating)?\s*(class|struct|enum|extension|func)\b', s) is not None


def decl_summary(line: str) -> (str, str):
    s = line.strip()
    m = SIMPLE_DECL_RE.search(s)
    if m:
        kind = m.group(1)
        name = m.group(2)
        return kind, name
    m2 = FUNC_RE.search(s)
    if m2:
        return 'func', m2.group(1)
    # fallback
    parts = s.split()
    if parts:
        return parts[0], parts[1] if len(parts) > 1 else ''
    return 'declaration', ''


def generate_decl_comment(kind, name):
    if kind == 'class':
        return f"/// Class {name}: Responsible for the lifecycle, state, and behavior related to {name}."
    if kind == 'struct':
        return f"/// Struct {name}: Value type that models the {name} data and related helpers."
    if kind == 'enum':
        return f"/// Enum {name}: Represents the possible values for {name}."
    if kind == 'extension':
        return f"/// Extension {name}: Adds focused functionality to {name}."
    return f"/// {kind} {name}: Declaration for {name}."


def generate_func_comment(line: str):
    # Extract name, params, return
    m = FUNC_RE.search(line)
    if not m:
        name = line.strip().split()[1] if len(line.strip().split()) > 1 else ''
        params = ''
        ret = 'Void'
    else:
        name = m.group(1)
        params = m.group(2).strip()
        ret = m.group(3) if m.group(3) else 'Void'

    # Format inputs
    if not params:
        input_desc = 'None'
    else:
        # normalize params: remove default values and types kept as-is
        parts = [p.strip() for p in params.split(',') if p.strip()]
        cleaned = []
        for p in parts:
            # keep the label and type if present
            cleaned.append(p)
        input_desc = '; '.join(cleaned) if cleaned else 'None'

    desc = f"/// @Description: Performs the {name} operation."
    inp = f"/// @Input: {input_desc}"
    out = f"/// @Output: {ret}"
    return [desc, inp, out]


def process_file(path: str, root: str) -> bool:
    with open(path, 'r', encoding='utf-8') as f:
        original = f.read()
    no_comments = remove_comments(original)
    lines = no_comments.splitlines()
    decl_positions = extract_decls(lines)

    # build header with list of top-level decl names (first pass)
    top_names = []
    for (a,b) in decl_positions:
        # take the first non-attribute line
        line = lines[b].strip()
        kind, name = decl_summary(line)
        top_names.append((kind, name))

    rel = os.path.relpath(path, root)
    header_block = ["/*"]
    header_block.append(f" File: {os.path.basename(path)}")
    purposes = ', '.join([k + ' ' + n for k, n in top_names][:8]) or 'Swift declarations for the Flux app.'
    header_block.append(f" Purpose: {purposes}")
    header_block.append(f" Location: {rel}")
    header_block.append("*/")
    header_block.append("")

    new_lines = header_block[:]
    i = 0
    n = len(lines)
    decl_index = 0
    while i < n:
        # if attribute block leading to declaration
        if lines[i].strip().startswith('@'):
            j = i
            while j < n and lines[j].strip().startswith('@'):
                j += 1
            if j < n and is_declaration_line(lines[j]):
                kind, name = decl_summary(lines[j])
                if kind in ('class', 'struct'):
                    new_lines.append(generate_decl_comment(kind, name))
                if kind == 'func':
                    for cl in generate_func_comment(lines[j]):
                        new_lines.append(cl)
                # copy attribute block and declaration
                while i <= j:
                    new_lines.append(lines[i])
                    i += 1
                continue
            else:
                # just copy attribute-like lines
                new_lines.append(lines[i])
                i += 1
                continue
        if is_declaration_line(lines[i]):
            kind, name = decl_summary(lines[i])
            if kind in ('class', 'struct'):
                new_lines.append(generate_decl_comment(kind, name))
                new_lines.append(lines[i])
                i += 1
                continue
            if kind == 'func':
                for cl in generate_func_comment(lines[i]):
                    new_lines.append(cl)
                new_lines.append(lines[i])
                i += 1
                continue
            # other declarations: just copy
            new_lines.append(lines[i])
            i += 1
            continue
        new_lines.append(lines[i])
        i += 1

    out = '\n'.join(new_lines) + ('\n' if not new_lines[-1].endswith('\n') else '')
    # backup
    bak = path + '.bak'
    try:
        if not os.path.exists(bak):
            with open(bak, 'w', encoding='utf-8') as f:
                f.write(original)
    except Exception:
        pass
    with open(path, 'w', encoding='utf-8') as f:
        f.write(out)
    return True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', default='.', help='Root path to search for .swift files')
    parser.add_argument('--include-hidden', action='store_true', help='Include hidden directories (dot-prefixed)')
    args = parser.parse_args()
    root = os.path.abspath(args.root)
    count = 0
    for dirpath, dirnames, filenames in os.walk(root):
        # optionally skip hidden folders like .git unless include-hidden is set
        if not args.include_hidden and any(part.startswith('.') for part in os.path.relpath(dirpath, root).split(os.sep)):
            continue
        for fn in filenames:
            if fn.endswith('.swift'):
                path = os.path.join(dirpath, fn)
                print('Processing', path)
                try:
                    process_file(path, root)
                    count += 1
                except Exception as e:
                    print('Error processing', path, e)
    print(f'Processed {count} .swift files under {root}')

if __name__ == '__main__':
    main()

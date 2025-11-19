import re

def extract_declarations(steps):
    all_text = "\n".join(step.text for step in steps)
    props = set()
    types = set()
    functions = {}

    # Detect function declarations: f : A → B
    func_matches = re.findall(r'\b([a-z][A-Za-z0-9_]*)\s*:\s*([A-Z][A-Za-z0-9_]*)\s*→\s*([A-Z][A-Za-z0-9_]*)', all_text)
    for f, A, B in func_matches:
        functions[f] = (A, B)
        types.update([A, B])

    # Detect x ∈ A → x : A
    membership_matches = re.findall(r'([a-z][A-Za-z0-9_]*)\s*∈\s*([A-Z][A-Za-z0-9_]*)', all_text)
    for x, A in membership_matches:
        functions[x] = A
        types.add(A)

    # Detect capitalized identifiers in the goal line
    goal_text = steps[0].text[len("proof:"):].strip()
    for token in re.findall(r'\b[A-Z][A-Za-z0-9_]*\b', goal_text):
        if token not in {'Prop', 'Type'}:
            props.add(token)

    return props, types, functions

def translate_to_lean(steps):
    if not steps or not steps[0].text.startswith("proof:"):
        raise ValueError("First line must start with 'proof:'")

    goal = steps[0].text[len("proof:"):].strip().rstrip(":")

    # Extract types and identifiers
    props, types, functions = extract_declarations(steps)

    # Prelude and declarations
    decl_lines = ["import logic.basic", "open classical"]

    for T in sorted(types):
        decl_lines.append(f"variable {T} : Type")

    for P in sorted(props):
        if P not in types:
            decl_lines.append(f"variable {P} : Prop")

    for name, val in sorted(functions.items()):
        if isinstance(val, tuple):
            decl_lines.append(f"variable {name} : {val[0]} → {val[1]}")
        else:
            decl_lines.append(f"variable {name} : {val}")

    decl_lines.append("")

    # Header
    header = f"theorem user_theorem : {goal} :=\nbegin"

    # Keyword mapping
    indent_map = {
        "assume": "intros",
        "let": "let",
        "have": "have",
        "so": "--",
        "then": "--",
        "show": "exact"
    }

    body = []
    for step in steps[1:]:
        text = step.text.strip()
        if text.upper() == "QED":
            continue

        tokens = text.split(maxsplit=1)
        keyword = tokens[0]
        content = tokens[1] if len(tokens) > 1 else ""
        lean_keyword = indent_map.get(keyword.lower(), "--")

        # Apply custom translations
        if keyword.lower() == "assume" and content.replace(" ", "") == "A∧B":
            line = "  " * step.indent + "intros h,"
        elif keyword.lower() == "have" and content.strip() == "A":
            line = "  " * step.indent + "have ha : A := and.left h,"
        elif keyword.lower() == "have" and content.strip() == "B":
            line = "  " * step.indent + "have hb : B := and.right h,"
        elif keyword.lower() == "show" and content.replace(" ", "") in {"B∧A", "B ∧ A"}:
            line = "  " * step.indent + "exact and.intro hb ha,"
        else:
            line = "  " * step.indent + f"{lean_keyword} {content},".strip()

        body.append(line)

    return "\n".join(decl_lines + [header] + body + ["end"])

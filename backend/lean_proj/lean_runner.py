import subprocess
import tempfile
import os

def run_lean(lean_code: str):
    with tempfile.NamedTemporaryFile(mode="w", suffix=".lean", delete=False, encoding="utf-8") as f:
        f.write(lean_code)
        filename = f.name

    print("[RUNNING LEAN]")  # <--- Add this

    try:
        result = subprocess.run(
            ["lean", filename],
            capture_output=True,
            timeout=10,
            encoding="utf-8",
            errors="replace"
        )

        print("[LEAN STDOUT]", result.stdout)
        print("[LEAN STDERR]", result.stderr)
        print("[RETURN CODE]", result.returncode)

        stdout = result.stdout or ""
        stderr = result.stderr or ""

        errors = parse_lean_errors(stdout)
        explanations = [explain_lean_error(e) for e in errors]

        return {
            "stdout": stdout,
            "stderr": stderr,
            "errors": errors,
            "explanations": explanations,
            "success": result.returncode == 0
        }

    finally:
        os.unlink(filename)



def parse_lean_errors(stdout: str):
    """
    Extract the raw Lean error messages from stdout lines.
    """
    extracted = []
    for line in stdout.splitlines():
        if "error:" in line:
            parts = line.split("error:")
            if len(parts) > 1:
                extracted.append(parts[1].strip())
    return extracted

def explain_lean_error(message: str) -> str:
    if "unexpected token ':'" in message:
        return "Use ':=' to define, not ':'."
    elif "invalid 'end'" in message or "insufficient scopes" in message:
        return "Missing or unmatched 'begin'."
    elif "unknown identifier" in message:
        return "You're using an undefined name."
    elif "failed to unify" in message:
        return "Mismatch between what was expected and given."
    elif "expected expression" in message:
        return "Missing value after 'have' or 'show'."
    else:
        return "Check syntax or structure."

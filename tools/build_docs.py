"""Build API documentation and reject diagnostics even when Nim exits zero."""

import argparse
from pathlib import Path
import re
import subprocess
import sys

DIAGNOSTIC = re.compile(
    r"^(?:.+\(\d+,\s*\d+\)\s+)?(?:Error|Warning):", re.MULTILINE
)


def has_diagnostics(output):
    return DIAGNOSTIC.search(output) is not None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--outdir", type=Path, default=Path("build") / "docs")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    output = args.outdir if args.outdir.is_absolute() else root / args.outdir
    result = subprocess.run(
        [
            "nim", "doc", "--threads:on", "--project", "--index:on",
            "--hints:off", "--colors:off", f"-p:{root / 'src'}",
            f"--outdir:{output}", str(root / "src" / "nimnet.nim"),
        ],
        cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, encoding="utf-8",
    )
    print(result.stdout, end="")
    if result.returncode != 0 or has_diagnostics(result.stdout):
        print("API documentation failed: compiler/doc diagnostics are not allowed.", file=sys.stderr)
        return 1
    for name in ("nimnet.html", "theindex.html"):
        if not (output / name).is_file():
            print(f"API documentation output is missing: {name}", file=sys.stderr)
            return 1
    print(f"API documentation generated in {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

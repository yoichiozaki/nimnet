"""Create a coverage badge only from nonempty, internally consistent LCOV data."""

import argparse
import json
from pathlib import Path


def coverage_counts(content):
    total = covered = records = 0
    source = None
    lines = hits = None
    for line in content.splitlines():
        if line.startswith("SF:"):
            if source is not None:
                raise ValueError("Unterminated LCOV record")
            source = line[3:]
            if not source:
                raise ValueError("Empty LCOV source path")
            lines = hits = None
        elif line.startswith(("LF:", "LH:")):
            if source is None:
                raise ValueError("LCOV counts without a source")
            value = int(line[3:])
            if value < 0:
                raise ValueError("Negative LCOV count")
            if line.startswith("LF:"):
                if lines is not None:
                    raise ValueError("Duplicate LCOV line count")
                lines = value
            else:
                if hits is not None:
                    raise ValueError("Duplicate LCOV hit count")
                hits = value
        elif line == "end_of_record":
            if source is None or lines is None or hits is None or hits > lines:
                raise ValueError("Incomplete/inconsistent LCOV record")
            total += lines
            covered += hits
            records += 1
            source = None
    if source is not None or records == 0 or total == 0:
        raise ValueError("LCOV data contains no complete executable source coverage")
    return covered, total


def make_badge(content):
    covered, total = coverage_counts(content)
    percent = covered / total * 100
    color = (
        "brightgreen" if percent >= 80 else
        "green" if percent >= 60 else
        "yellowgreen" if percent >= 40 else
        "orange" if percent >= 20 else "red"
    )
    return {
        "schemaVersion": 1,
        "label": "coverage",
        "message": f"{percent:.2f}%",
        "color": color,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    badge = make_badge(args.input.read_text(encoding="utf-8"))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(badge, indent=2) + "\n", encoding="utf-8")
    print(f"Coverage: {badge['message']}")


if __name__ == "__main__":
    main()

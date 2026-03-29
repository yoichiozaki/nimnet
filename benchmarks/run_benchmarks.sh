#!/usr/bin/env bash
# Run nimnet and NetworkX benchmarks, merge results into a single CSV.
#
# Usage:
#   cd nimnet/
#   bash benchmarks/run_benchmarks.sh
#
# Prerequisites:
#   - Nim compiler (nim, nimble)
#   - Python 3 with networkx:  pip install networkx
#
# Outputs:
#   benchmarks/results/nimnet.csv
#   benchmarks/results/networkx.csv   (if Python + NetworkX available)
#   benchmarks/results/combined.csv

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"

mkdir -p "$RESULTS_DIR"

echo "=== Building nimnet benchmark (release mode) ==="
nim c -d:release -d:danger --opt:speed -p:src \
  --nimcache:"$ROOT_DIR/build/nimcache/bench" \
  -o:"$ROOT_DIR/build/bench_nimnet" \
  "$SCRIPT_DIR/bench_nimnet.nim"

echo ""
echo "=== Running nimnet benchmarks ==="
"$ROOT_DIR/build/bench_nimnet" | tee "$RESULTS_DIR/nimnet.csv"

echo ""

# NetworkX (optional)
if command -v python3 &>/dev/null && python3 -c "import networkx" 2>/dev/null; then
  echo "=== Running NetworkX benchmarks ==="
  python3 "$SCRIPT_DIR/bench_networkx.py" | tee "$RESULTS_DIR/networkx.csv"
elif command -v python &>/dev/null && python -c "import networkx" 2>/dev/null; then
  echo "=== Running NetworkX benchmarks ==="
  python "$SCRIPT_DIR/bench_networkx.py" | tee "$RESULTS_DIR/networkx.csv"
else
  echo "Skipping NetworkX benchmarks (python3/networkx not found)"
fi

# Merge results
echo ""
echo "=== Merging results ==="
echo "library,benchmark,size,nodes,edges,time_seconds" > "$RESULTS_DIR/combined.csv"
for f in "$RESULTS_DIR"/nimnet.csv "$RESULTS_DIR"/networkx.csv; do
  if [ -f "$f" ]; then
    tail -n +2 "$f" >> "$RESULTS_DIR/combined.csv"
  fi
done

echo "Results written to $RESULTS_DIR/combined.csv"
echo ""
echo "=== Summary ==="
column -t -s, "$RESULTS_DIR/combined.csv" 2>/dev/null || cat "$RESULTS_DIR/combined.csv"

#!/usr/bin/env bash
# Run isolated benchmarks against the same generated fixture files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"
PYTHON="${PYTHON:-python3}"
RUN_NETWORKX=true
PREFIX=""
BENCHMARK="bench_nimnet"
PYTHON_BENCHMARK="bench_networkx.py"
SUITE="main"
for arg in "$@"; do
  case "$arg" in
    --nim-only) RUN_NETWORKX=false ;;
    --micro)
      PREFIX="micro_"
      BENCHMARK="bench_micro"
      PYTHON_BENCHMARK="bench_micro_networkx.py"
      SUITE="micro"
      ;;
    *)
      echo "Usage: $0 [--nim-only] [--micro]" >&2
      exit 2
      ;;
  esac
done

mkdir -p "$RESULTS_DIR" "$ROOT_DIR/build"
for name in nimnet.csv networkx.csv combined.csv metadata.json; do
  rm -f "$RESULTS_DIR/${PREFIX}${name}"
done
if "$RUN_NETWORKX"; then
  "$PYTHON" -c "import networkx, numpy, scipy"
fi
"$PYTHON" "$SCRIPT_DIR/fixtures.py"

echo "=== Building nimnet benchmark (release mode) ==="
nim c --threads:on --hints:off -d:release --opt:speed "-p:$ROOT_DIR/src" \
  --nimcache:"$ROOT_DIR/build/nimcache/$BENCHMARK" \
  -o:"$ROOT_DIR/build/$BENCHMARK" \
  "$SCRIPT_DIR/$BENCHMARK.nim"

echo "=== Running nimnet benchmarks ==="
"$ROOT_DIR/build/$BENCHMARK" | tee "$RESULTS_DIR/${PREFIX}nimnet.csv"
inputs=("$RESULTS_DIR/${PREFIX}nimnet.csv")
metadata_args=("$SCRIPT_DIR/fixtures.py" --metadata "$RESULTS_DIR/${PREFIX}metadata.json" --suite "$SUITE")

if "$RUN_NETWORKX"; then
  echo "=== Running NetworkX benchmarks ==="
  "$PYTHON" "$SCRIPT_DIR/$PYTHON_BENCHMARK" | tee "$RESULTS_DIR/${PREFIX}networkx.csv"
  inputs+=("$RESULTS_DIR/${PREFIX}networkx.csv")
  metadata_args+=(--include-networkx)
else
  echo "NetworkX explicitly skipped (--nim-only)."
fi

"$PYTHON" "${metadata_args[@]}"
"$PYTHON" "$SCRIPT_DIR/compare_results.py" --suite "$SUITE" \
  --output "$RESULTS_DIR/${PREFIX}combined.csv" "${inputs[@]}"

echo "Results written to $RESULTS_DIR/${PREFIX}combined.csv"

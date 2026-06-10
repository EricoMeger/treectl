#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TREECTL="${TREECTL_BIN:-$ROOT_DIR/../build/treectl/treectl}"
RESULTS_DIR="$SCRIPT_DIR/../results"
DATA_DIR="$SCRIPT_DIR/../data"
GEN="$SCRIPT_DIR/gen_keys.py"

mkdir -p "$RESULTS_DIR" "$DATA_DIR"

PASS=0; FAIL=0

bench_insert() {
    local name="$1" order="$2" n="$3"
    local cmds="$DATA_DIR/${name}.txt"
    local saved="$DATA_DIR/${name}.btree"
    [[ ! -d "$RESULTS_DIR/bench" ]] && mkdir -p "$RESULTS_DIR/bench"
    local log="$RESULTS_DIR/bench/${name}.log"

    echo -n "  $name (n=$n, ordem=$order) ... "
    python3 "$GEN" sequential "$n" --output "$cmds"
    echo "save $saved" >> "$cmds"
    echo "exit" >> "$cmds"

    start=$(date +%s%N)
    "$TREECTL" --order "$order" < "$cmds" > "$log" 2>&1
    end=$(date +%s%N)
    elapsed_ms=$(( (end - start) / 1000000 ))

    file_size=$(wc -c < "$saved")
    node_count=$(grep -c "^\[" "$saved" || true)

    echo "OK (${elapsed_ms}ms, ${node_count} nós, ${file_size} bytes)"
    PASS=$((PASS + 1))

    echo "$saved"
}

echo "════════════════════════════════════════"
echo "  Testes grandes (100k+ chaves)"
echo "════════════════════════════════════════"

echo ""
echo " Inserção em massa (ordem 5) "
bench_insert "large_o5_500k" 5 500000
bench_insert "large_o5_5kk" 5 5000000
bench_insert "large_o5_500kk" 5 500000000

echo ""
echo " Inserção em massa (ordem 50) "
bench_insert "large_o50_500k" 50 500000
bench_insert "large_o50_5kk" 50 5000000
bench_insert "large_o50_500kk" 50 500000000


echo ""
echo "────────────────────────────────────────"
echo "  Resultado: $PASS passou"
echo "────────────────────────────────────────"
[[ $FAIL -eq 0 ]]

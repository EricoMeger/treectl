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

run_test() {
    local name="$1" order="$2" n="$3" mode="$4"
    local cmds="$DATA_DIR/${name}.txt"
    local saved="$DATA_DIR/${name}.btree"
    [[ ! -d "$RESULTS_DIR/run" ]] && mkdir -p "$RESULTS_DIR/run"
    local log="$RESULTS_DIR/run/${name}.log"

    echo -n "  $name ($n ops) ... "
    python3 "$GEN" "$mode" "$n" --output "$cmds"
    echo "save $saved" >> "$cmds"
    echo "exit" >> "$cmds"

    time_output=$({ time "$TREECTL" --order "$order" < "$cmds" > "$log" 2>&1; } 2>&1 | grep real | awk '{print $2}')
    echo "OK ($time_output)"
    PASS=$((PASS + 1))
}

echo "════════════════════════════════════════"
echo "  Testes médios (milhares de chaves)"
echo "════════════════════════════════════════"

echo ""
echo " Estrutura (ordem 5) "
run_test "medium_o5_insert" 5 1000 "insert_only"
run_test "medium_o5_mixed" 5 1000 "mixed"
run_test "medium_o5_seq" 5 1000 "sequential"
run_test "medium_o5_worst" 5 1000 "worst_case"

echo ""
echo " Estrutura (ordem 50) ────────────────"
run_test "medium_o50_insert" 50 1000 "insert_only"
run_test "medium_o50_mixed" 50 1000 "mixed"
run_test "medium_o50_seq" 50 1000 "sequential"
run_test "medium_o50_worst" 50 1000 "worst_case"

echo ""
echo "────────────────────────────────────────"
echo "  Resultado: $PASS passou, $FAIL falhou"
echo "────────────────────────────────────────"
[[ $FAIL -eq 0 ]]

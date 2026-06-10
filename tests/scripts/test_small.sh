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

    echo -n " $name ... "

    python3 "$GEN" "$mode" "$n" --output "$cmds"

    echo "save $saved" >> "$cmds"
    echo "exit" >> "$cmds"

    "$TREECTL" --order "$order" < "$cmds" > "$log" 2>&1
    echo "OK"
    PASS=$((PASS + 1))
}

echo "════════════════════════════════════════"
echo "  Testes pequenos (dezenas de chaves)"
echo "════════════════════════════════════════"

echo ""
echo " Estrutura (ordem 3) "
run_test "small_o3_insert" 3 50 "insert_only"
run_test "small_o3_mixed" 3 50 "mixed"
run_test "small_o3_seq" 3 50 "sequential"

echo ""
echo " Estrutura (ordem 5) "
run_test "small_o5_insert" 5 80 "insert_only"
run_test "small_o5_mixed" 5 80 "mixed"
run_test "small_o5_seq" 5 80 "sequential"

echo ""
echo "────────────────────────────────────────"
echo "  Resultado: $PASS passou, $FAIL falhou"
echo "────────────────────────────────────────"
[[ $FAIL -eq 0 ]]

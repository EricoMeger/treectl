#!/usr/bin/env bash
# Requer build com TREECTL_USE_COMPRESSION=ON e o executável do compressor.
# Pode ser rodado standalone: usa os arquivos .btree gerados pelos outros testes,
# ou gera os seus próprios se eles não existirem.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TREECTL="${TREECTL_BIN:-$ROOT_DIR/../build/treectl/treectl}"
COMPRESSOR="${COMPRESSOR_BIN:-$ROOT_DIR/../build/huffman-lzw-compressor/compressor}"
RESULTS_DIR="$SCRIPT_DIR/../results"
DATA_DIR="$SCRIPT_DIR/../data"
GEN="$SCRIPT_DIR/gen_keys.py"

mkdir -p "$RESULTS_DIR" "$DATA_DIR"

PASS=0; FAIL=0

ensure_btree() {
    local name="$1" order="$2" n="$3"
    local saved="$DATA_DIR/${name}.btree"
    if [[ ! -f "$saved" ]]; then
        echo "  (gerando $name com $n chaves...)" >&2
        python3 "$GEN" sequential "$n" | \
            { cat; echo "save $saved"; echo "exit"; } | \
            "$TREECTL" --order "$order" > /dev/null 2>&1
    fi
    echo "$saved"
}

compare_compression() {
    local label="$1" btree_file="$2"
    local log="$RESULTS_DIR/compress_${label}.log"

    echo -n "  $label ... "

    if [[ ! -x "$COMPRESSOR" ]]; then
        echo "PULADO (compressor não encontrado em $COMPRESSOR)"
        return
    fi

    orig_size=$(wc -c < "$btree_file")
    "$COMPRESSOR" compress "$btree_file" > "$log" 2>&1

    huff_file="${btree_file}.huff"
    lzw_file="${btree_file}.lzw"

    huff_out="$(dirname "$RESULTS_DIR")/compress/$(basename "$btree_file").huffman"
    lzw_out="$(dirname "$RESULTS_DIR")/compress/$(basename "$btree_file").lzw"

    if [[ -f "$huff_out" && -f "$lzw_out" ]]; then
        huff_size=$(wc -c < "$huff_out")
        lzw_size=$(wc -c < "$lzw_out")

        python3 - "$orig_size" "$huff_size" "$lzw_size" << 'PYEOF'
import sys
orig, huff, lzw = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
print(f"OK ✓")
print(f"    original : {orig:>10,} bytes")
print(f"    huffman  : {huff:>10,} bytes  ({huff*100/orig:5.1f}%  economia {(1-huff/orig)*100:4.1f}%)")
print(f"    lzw      : {lzw:>10,} bytes  ({lzw*100/orig:5.1f}%  economia {(1-lzw/orig)*100:4.1f}%)")
winner = "huffman" if huff < lzw else "lzw" if lzw < huff else "empate"
print(f"    vencedor : {winner}")
PYEOF
    fi
}

echo "════════════════════════════════════════"
echo "  Testes de compressão"
echo "════════════════════════════════════════"

echo ""
echo " Compressão standalone (via compressor)──"
f1=$(ensure_btree "comp_o5_1k"   5   1000)
f2=$(ensure_btree "comp_o5_10k"  5   10000)
f3=$(ensure_btree "comp_o50_1k"  50  1000)
f4=$(ensure_btree "comp_o50_10k" 50  10000)
f5=$(ensure_btree "comp_o50_100k" 50  100000)
f6=$(ensure_btree "large_o50_500k" 50 500000)

compare_compression "ordem5_1k"   "$f1"
compare_compression "ordem5_10k"  "$f2"
compare_compression "ordem50_1k"  "$f3"
compare_compression "ordem50_10k" "$f4"
compare_compression "ordem50_100k" "$f5"
compare_compression "large_o50_500k" "$f6"

echo ""
echo "────────────────────────────────────────"
echo "  CONCLUÍDO: ENCONTRE OS LOGS EM $RESULTS_DIR/compress_*.log"
echo "────────────────────────────────────────"
[[ $FAIL -eq 0 ]]

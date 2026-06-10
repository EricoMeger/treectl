#!/usr/bin/env python3
"""
gen_keys.py — gera arquivos de comandos para o treectl.

Uso:
    python3 gen_keys.py <modo> <n> [--seed <s>] [--output <arquivo>]

Modos:
    insert_only   n inserções
    mixed         70% insert, 20% read, 10% delete (em ordem aleatória)
    worst_case    inserções em ordem crescente de hash (pior caso para splits)
    sequential    strings "key_000001", "key_000002", ...

Exemplos:
    python3 gen_keys.py insert_only 100
    python3 gen_keys.py mixed 10000 --seed 42 --output /tmp/cmds.txt
"""

import argparse
import random
import string
import sys

def random_key(length=8, rng=None):
    rng = rng or random
    chars = string.ascii_lowercase + string.digits
    return ''.join(rng.choice(chars) for _ in range(length))

def gen_insert_only(n, rng):
    keys = [random_key(rng=rng) for _ in range(n)]
    return [f"insert {k}" for k in keys]

def gen_mixed(n, rng):
    # Gera um pool de chaves e mistura operações
    pool_size = max(n // 3, 10)
    pool = [random_key(rng=rng) for _ in range(pool_size)]
    inserted = []
    cmds = []

    for _ in range(n):
        r = rng.random()
        if r < 0.70 or not inserted:
            k = rng.choice(pool)
            cmds.append(f"insert {k}")
            if k not in inserted:
                inserted.append(k)
        elif r < 0.90 and inserted:
            k = rng.choice(inserted)
            cmds.append(f"read {k}")
        else:
            k = rng.choice(inserted)
            cmds.append(f"delete {k}")
            inserted.remove(k)

    return cmds

def gen_sequential(n, _rng):
    return [f"insert key_{i:08d}" for i in range(1, n + 1)]

def gen_worst_case(n, _rng):
    # Insere strings que geram hashes em ordem crescente
    # (força splits consecutivos sempre no mesmo lado)
    return [f"insert worst_{i:08d}" for i in range(1, n + 1)]

MODES = {
    "insert_only": gen_insert_only,
    "mixed":       gen_mixed,
    "sequential":  gen_sequential,
    "worst_case":  gen_worst_case,
}

def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("mode",   choices=MODES.keys())
    parser.add_argument("n",      type=int)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--output", default=None,
                        help="Arquivo de saída (padrão: stdout)")
    args = parser.parse_args()

    rng = random.Random(args.seed)
    cmds = MODES[args.mode](args.n, rng)

    out = open(args.output, "w") if args.output else sys.stdout
    for cmd in cmds:
        out.write(cmd + "\n")
    if args.output:
        out.close()
        print(f"Gerado: {args.output} ({len(cmds)} comandos)", file=sys.stderr)

if __name__ == "__main__":
    main()

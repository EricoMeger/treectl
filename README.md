# treectl

CLI para operações em uma Árvore B com chaves do tipo string.

As chaves são armazenadas internamente como hash MurmurHash32 acompanhado da string original, garantindo ordenação e desambiguação em caso de colisão. Cada operação reporta métricas de nós visitados, tempo e uso de memória.

O treectl pode ser compilado de forma standalone ou integrado ao [compressor](https://github.com/PLACEHOLDER/huffman-lzw-compressor), habilitando compressão LZW ou Huffman diretamente no `save` e `load`.

---

## Integrantes

- Érico Meger
- Eros Henrique Lunardon Andrade

---

## Estrutura do repositório

```
treectl/
├── include/
│   ├── btree/
│   │   ├── btree.hpp          # Interface da B-Tree e tipos internos (Key, Node)
│   │   └── btree_types.hpp    # OpResult -> resultado público das operações
│   ├── cli/
│   │   └── orchestrator.hpp   # Interface do orquestrador de comandos
│   ├── hash/
│   │   ├── hash_function.hpp  # Interface base para funções de hash
│   │   └── algorithms/
│   │       └── murmurhash.hpp # MurmurHash32
│   └── utils/
│       └── metrics.hpp        # Timer e medição de memória
├── src/
│   ├── btree/
│   │   └── btree.cpp          # Implementação da B-Tree (insert, read, delete, save, load)
│   ├── cli/
│   │   └── orchestrator.cpp   # Parsing de comandos e despacho com coleta de métricas
│   ├── hash/algorithms/
│   │   └── murmurhash.cpp     # Implementação do MurmurHash32
│   └── utils/
│       └── metrics.cpp        # Implementação do timer e leitura de memória (/proc)
├── main.cpp                   # loop de comandos e argumentos CLI
├── CMakeLists.txt             # Build standalone ou integrado ao compressor
└── setup.sh                  # Monta o workspace com treectl + compressor
```

---

## Compilação

### Standalone (sem compressão)

```bash
cmake -B build -DTREECTL_USE_COMPRESSION=OFF
cmake --build build
```

### Integrado ao compressor

O `setup.sh` monta o workspace com os dois projetos e o CMakeLists raiz:

```bash
./setup.sh --compressor-repo https://github.com/Eroshla/huffman-lzw-compressor/
cd ../trabalho2-workspace
cmake -B build
cmake --build build
```

O binário gerado fica em `build/treectl/treectl`.

---

## Uso

```
./treectl --order <N> [--compressor <huffman|lzw>]
```

| Argumento | Descrição |
|---|---|
| `--order <N>` | Ordem da B-Tree (mínimo 3). Obrigatório. |
| `--compressor <alg>` | Comprime no `save` e descomprime no `load`. Requer build com compressor. |

### Exemplos

```bash
# Ordem 5, sem compressão
./treectl --order 5

# Ordem 50, comprimindo com LZW
./treectl --order 50 --compressor lzw
```

---

## Comandos disponíveis

| Comando | Descrição |
|---|---|
| `insert <chave>` | Insere a chave na árvore |
| `read <chave>` | Busca a chave e reporta se foi encontrada |
| `delete <chave>` | Remove a chave da árvore |
| `save <arquivo>` | Serializa a árvore em arquivo texto |
| `load <arquivo>` | Carrega a árvore a partir de um arquivo |
| `print` | Exibe todos os nós da árvore no terminal |
| `help` | Lista os comandos disponíveis |
| `exit` | Encerra o programa |

Linhas começando com `#` são ignoradas, o que permite usar arquivos de script como entrada.

---

## Formato do arquivo salvo

```
BTREE order=5 nodes=4 root=3

[0] LEAF keys=2
keys: 2ad1f31b:date f9a511ba:cherry

[1] LEAF keys=1
keys: 9416ac93:apple

[2] LEAF keys=1
keys: f5622baf:banana

[3] ROOT INTERNAL keys=2 children=3
keys: 2cb5a21f:cherry ce91997f:elderberry
children: 1 0 2
```

Cada chave é armazenada como `<hash_hex>:<string_original>`. O hash é usado para ordenação; a string original é usada para confirmar buscas e resolver colisões de hash.

Quando compilado com `--compressor`, o `save` gera adicionalmente um arquivo `.lzw` ou `.huffman` com o conteúdo comprimido. O `load` descomprime automaticamente se o arquivo comprimido estiver presente.

---

## Métricas

Cada operação imprime uma linha de métricas:

```
[insert] key="banana" | nodes_visited=2 | time=0.043ms | memory=4008KB
```

| Campo | Descrição |
|---|---|
| `nodes_visited` | Nós percorridos durante a operação |
| `time` | Tempo de execução em milissegundos |
| `memory` | RSS do processo ao final da operação (via `/proc/self/status`) |

---

## Decisões de implementação

**Chaves como hash + string original**: o MurmurHash32 é usado para ordenação e navegação na árvore, aproveitando a implementação já existente de outro trabalho. A string original é mantida junto para desambiguar colisões (que podem ocorrer em escala com 32 bits).

**Serialização em texto legível**: o formato foi escolhido por ser fácil de inspecionar visualmente durante o desenvolvimento e comprimir bem com LZW, dado o padrão repetitivo dos cabeçalhos de nó.

**Interface abstrata para compressores**: o treectl depende apenas de `Compressor` e `Decompressor` (interfaces puras definidas em `compressor.hpp`). A escolha do algoritmo é feita no `main.cpp` e injetada no orchestrator, sem nenhum acoplamento no código da árvore.

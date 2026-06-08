#include "../../include/cli/orchestrator.hpp"

#include <iostream>
#include <sstream>

Orchestrator::Orchestrator(int order) : tree_(order) {}

bool Orchestrator::handle(const std::string& line) {
    std::istringstream ss(line);
    std::string cmd;
    ss >> cmd;

    if (cmd.empty() || cmd[0] == '#') return true; 

    if (cmd == "exit" || cmd == "quit") return false;

    std::string arg;
    ss >> arg;

    if (cmd == "insert") cmd_insert(arg);
    else if (cmd == "read")   cmd_read(arg);
    else if (cmd == "delete") cmd_delete(arg);
    else if (cmd == "save")   cmd_save(arg);
    else if (cmd == "load")   cmd_load(arg);
    else if (cmd == "print")  cmd_print();
    else if (cmd == "help")   cmd_help();
    else {
        std::cout << "Unrecognized command \"" << cmd
                  << "\". Type \"help\" to see the available commands.\n";
    }

    return true;
}

void Orchestrator::cmd_insert(const std::string& key) {
    if (key.empty()) { std::cout << "Usage: insert <key>\n"; return; }

    Timer t;
    auto result = tree_.insert(key);
    double ms = t.elapsed_ms();

    Metrics m{result.nodes_visited, ms, current_memory_bytes()};

    if (result.found)
        std::cout << "OK inserted: \"" << key << "\"\n";
    else
        std::cout << "WARN: key \"" << key << "\" already exists in the tree.\n";

    print_metrics("insert", key, m);
}

void Orchestrator::cmd_read(const std::string& key) {
    if (key.empty()) { std::cout << "Usage: read <key>\n"; return; }

    Timer t;
    auto result = tree_.read(key);
    double ms = t.elapsed_ms();

    Metrics m{result.nodes_visited, ms, current_memory_bytes()};

    if (result.found)
        std::cout << "FOUND: \"" << key << "\"\n";
    else
        std::cout << "NOT FOUND: \"" << key << "\"\n";

    print_metrics("read", key, m);
}

void Orchestrator::cmd_delete(const std::string& key) {
    if (key.empty()) { std::cout << "Usage: delete <key>\n"; return; }

    Timer t;
    auto result = tree_.remove(key);
    double ms = t.elapsed_ms();

    Metrics m{result.nodes_visited, ms, current_memory_bytes()};

    if (result.found)
        std::cout << "OK removed: \"" << key << "\"\n";
    else
        std::cout << "NOT FOUND: \"" << key << "\"\n";

    print_metrics("delete", key, m);
}

void Orchestrator::cmd_save(const std::string& filename) {
    if (filename.empty()) { std::cout << "Usage: save <file>\n"; return; }

    Timer t;
    bool ok = tree_.save(filename);
    double ms = t.elapsed_ms();

    if (ok)
        std::cout << "Tree saved to \"" << filename << "\" ("
                  << std::fixed << ms << "ms)\n";
    else
        std::cout << "ERROR: Could not save to \"" << filename << "\"\n";
}

void Orchestrator::cmd_load(const std::string& filename) {
    if (filename.empty()) { std::cout << "Usage: load <file>\n"; return; }

    Timer t;
    bool ok = tree_.load(filename);
    double ms = t.elapsed_ms();

    if (ok)
        std::cout << "Tree loaded from \"" << filename << "\" ("
                  << tree_.node_count() << " nodes, "
                  << std::fixed << ms << "ms)\n";
    else
        std::cout << "ERROR: Could not load from \"" << filename << "\"\n";
}

void Orchestrator::cmd_print() {
    tree_.print();
}

void Orchestrator::cmd_help() {
    std::cout <<
        "Available commands:\n"
        "  insert <key>   inserts the key into the tree\n"
        "  read   <key>   reads the key from the tree\n"
        "  delete <key>   deletes the key from the tree\n"
        "  save   <file>  saves the tree to a file\n"
        "  load   <file>  loads the tree from a file\n"
        "  print  prints the tree to the terminal\n"
        "  help   displays this help message\n"
        "  exit   exits the program\n";
}

#pragma once

#include "../btree/btree.hpp"
#include "../utils/metrics.hpp"
#include <string>

class Orchestrator {
public:
    explicit Orchestrator(int order);
    bool handle(const std::string& line);   //false = exit

private:
    BTree tree_;

    void cmd_insert(const std::string& key);
    void cmd_read  (const std::string& key);
    void cmd_delete(const std::string& key);
    void cmd_save  (const std::string& filename);
    void cmd_load  (const std::string& filename);
    void cmd_print ();
    void cmd_help  ();
};

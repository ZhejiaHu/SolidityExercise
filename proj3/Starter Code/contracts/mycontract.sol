// SPDX-License-Identifier: UNLICENSED

// DO NOT MODIFY BELOW THIS
pragma solidity ^0.8.17;

import "hardhat/console.sol";

contract Splitwise {
    // DO NOT MODIFY ABOVE THIS
    // ADD YOUR CONTRACT CODE BELOW

    uint32[][] private matrix;
    mapping(address => uint32) users;
    mapping(address => bool) has_user;
    uint32 private person_idx = 0;

    function user_exists(address key) public view returns (bool) {
        return has_user[key];
    }

    function lookup(address debtor, address creditor) public view returns (uint32 ret) {
        if (!user_exists(debtor) || !user_exists(creditor)) ret = 0;
        else ret = matrix[users[debtor]][users[creditor]];
    }

    function add_user(address user) private {
        users[user] = person_idx;
        has_user[user] = true;
        person_idx++;
        for (uint32 i = 0; i < matrix.length; i++) matrix[i].push();
        uint32[] memory new_array = new uint32[](person_idx);
        matrix.push(new_array);
    }

    function in_array(uint32[] memory array, uint32 element) private pure returns (bool) {
        for (uint32 i = 0; i < array.length; i++) if (array[i] == element) return true;
        return false;
    }

    function add_IOU(address creditor, uint32 amount) payable public {
        if (!user_exists(msg.sender)) add_user(msg.sender);
        if (!user_exists(creditor)) add_user(creditor);
        uint32 debtor_id = users[msg.sender];
        uint32 creditor_id = users[creditor];
        matrix[debtor_id][creditor_id] += amount;
        uint32[] memory path = new uint32[](matrix.length);
        bool[] memory visited = new bool[](matrix.length);
        find_path(creditor_id, debtor_id, path, visited, 0);
        uint32 curr_min = amount;
        for (uint32 i = 0; i < path.length; i++) if (curr_min > matrix[path[i]][path[(i + 1) % path.length]]) curr_min = matrix[path[i]][path[(i + 1) % path.length]];
        for (uint32 i = 0; i < path.length; i++) matrix[path[i]][path[(i + 1) % path.length]] -= curr_min;
    }

    function find_path(uint32 curr_vertex, uint32 destination, uint32[] memory path, bool[] memory visited, uint32 curr_idx) private {
        path[curr_idx] = curr_vertex;
        if (curr_vertex == destination) return;
        visited[curr_vertex] = true;
        for (uint32 nxt = 0; nxt < matrix.length; nxt++) if (!visited[nxt]) find_path(nxt, destination, path, visited, curr_idx + 1);
    }
}

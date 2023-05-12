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
    uint32[] path = new uint32[](matrix.length);
    bool[] visited = new bool[](matrix.length);


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
        path = new uint32[](matrix.length);
        visited = new bool[](matrix.length);
        matrix[debtor_id][creditor_id] += amount;
        find_path(creditor_id, debtor_id, 0);
        uint32 curr_min = amount;
        if (path[path.length - 1] != debtor_id) return;
        for (uint32 i = 0; i < path.length; i++) if (curr_min > matrix[path[i]][path[(i + 1) % path.length]]) curr_min = matrix[path[i]][path[(i + 1) % path.length]];
        for (uint32 i = 0; i < path.length; i++) matrix[path[i]][path[(i + 1) % path.length]] -= curr_min;
        for (uint i = 0; i < matrix.length; i++) {
            path[i] = 0;
            visited[i] = false;
        }
    }

    function find_path(uint32 curr_vertex, uint32 destination, uint32 curr_idx) private {
        path[curr_idx] = curr_vertex;
        if (curr_vertex == destination) return;
        visited[curr_vertex] = true;
        for (uint32 nxt = 0; nxt < matrix.length; nxt++)
            if (!visited[nxt] && matrix[curr_vertex][nxt] > 0)
                find_path(nxt, destination, curr_idx + 1);
    }
}

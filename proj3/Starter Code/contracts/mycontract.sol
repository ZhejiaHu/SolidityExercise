// SPDX-License-Identifier: UNLICENSED

// DO NOT MODIFY BELOW THIS
pragma solidity ^0.8.17;

import "hardhat/console.sol";

contract Splitwise {
    // DO NOT MODIFY ABOVE THIS
    // ADD YOUR CONTRACT CODE BELOW

    uint32[][] public matrix;
    mapping(address => uint32) public users;
    mapping(address => bool) has_user;
    address[] public all_clients;
    uint32 private person_idx = 0;
    uint256 public debug = 999;
    uint32[] path;
    bool[] visited;


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
        all_clients.push(user);
    }

    function in_array(uint32[] memory array, uint32 element) private pure returns (bool) {
        for (uint32 i = 0; i < array.length; i++) if (array[i] == element) return true;
        return false;
    }

    function add_IOU(address creditor, uint32 amount) public {
        if (!user_exists(msg.sender)) add_user(msg.sender);
        if (!user_exists(creditor)) add_user(creditor);
        uint32 debtor_id = users[msg.sender];
        uint32 creditor_id = users[creditor];
        path = new uint32[](matrix.length);
        visited = new bool[](matrix.length);
        matrix[debtor_id][creditor_id] += amount;
        uint32 len = find_path(creditor_id, debtor_id, 0);
        uint32 curr_min = amount;
        //debug = creditor_id;
        if (len == 1 || len == (1 << 32) - 1 || path[len] != debtor_id) return;
        for (uint32 i = 0; i <= len; i++) if (curr_min > matrix[path[i]][path[(i + 1) % (len + 1)]]) curr_min = matrix[path[i]][path[(i + 1) % path.length]];
        for (uint32 i = 0; i <= len; i++) matrix[path[i]][path[(i + 1) % (len + 1)]] -= curr_min;
        delete path;
        delete visited;
    }

    function find_path(uint32 curr_vertex, uint32 destination, uint32 curr_idx) private returns (uint32) {
        path[curr_idx] = curr_vertex;
        if (curr_vertex == 0 && destination == 4) debug = matrix[0][1];
        if (curr_vertex == destination) return curr_idx;
        visited[curr_vertex] = true;
        for (uint32 nxt = 0; nxt < matrix.length; nxt++) {
            uint32 cnt = 0;

            if (!visited[nxt] && matrix[curr_vertex][nxt] > 0) {
                if (curr_vertex == 1) {
                    cnt++;
                    //debug = matrix[curr_vertex][nxt];
                }
                uint32 result = find_path(nxt, destination, curr_idx + 1);
                if (result != (1 << 32 - 1)) return result;
            }
        }
        return (1 << 32) - 1;
    }

    function get_matrix() view public returns (uint32[][] memory) {
        return matrix;
    }

    function get_all_clients() view public returns (address[] memory) {
        return all_clients;
    }

    function get_user_id(address addr) view public returns(uint32) {
        return users[addr];
    }

}

// SPDX-License-Identifier: UNLICENSED

// DO NOT MODIFY BELOW THIS
pragma solidity ^0.8.17;

import "hardhat/console.sol";

contract Splitwise {
    // DO NOT MODIFY ABOVE THIS
    // ADD YOUR CONTRACT CODE BELOW

    uint32[][] public matrix;
    mapping(address => uint256) public users;
    address[] public all_clients;
    uint256[] path;
    bool[] visited;


    function user_exists(address key) public view returns (bool) {
        return users[key] > 0;
    }

    function lookup(address debtor, address creditor) public view returns (uint32 ret) {
        if (!user_exists(debtor) || !user_exists(creditor)) ret = 0;
        else ret = matrix[users[debtor] - 1][users[creditor] - 1];
    }

    function add_user(address user) private {
        users[user] = matrix.length + 1;
        for (uint32 i = 0; i < matrix.length; i++) matrix[i].push();
        uint32[] memory new_array = new uint32[](matrix.length + 1);
        matrix.push(new_array);
        all_clients.push(user);
    }

    function add_IOU(address creditor, uint32 amount) public {
        if (!user_exists(msg.sender)) add_user(msg.sender);
        if (!user_exists(creditor)) add_user(creditor);
        uint256 debtor_id = users[msg.sender] - 1;
        uint256 creditor_id = users[creditor] - 1;
        uint mat_len = matrix.length;
        path = new uint32[](mat_len);
        visited = new bool[](mat_len);
        matrix[debtor_id][creditor_id] += amount;
        uint256 len = find_path(creditor_id, debtor_id, 0);
        uint32 curr_min = amount;
        //debug = creditor_id;
        if (len == 1 || len == (1 << 32) - 1 || path[len] != debtor_id) return;
        uint256 next_len = len + 1;
        for (uint32 i = 0; i <= len; i++) if (curr_min > matrix[path[i]][path[(i + 1) % next_len]]) curr_min = matrix[path[i]][path[(i + 1) % path.length]];
        for (uint32 i = 0; i <= len; i++) matrix[path[i]][path[(i + 1) % next_len]] -= curr_min;
        delete path;
        delete visited;
    }

    function find_path(uint256 curr_vertex, uint256 destination, uint256 curr_idx) private returns (uint256) {
        path[curr_idx] = curr_vertex;
        if (curr_vertex == destination) return curr_idx;
        visited[curr_vertex] = true;
        for (uint32 nxt = 0; nxt < matrix.length; nxt++) {
            if (!visited[nxt] && matrix[curr_vertex][nxt] > 0) {
                uint256 result = find_path(nxt, destination, curr_idx + 1);
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

    function get_user_id(address addr) view public returns(uint256) {
        return users[addr] - 1;
    }

}

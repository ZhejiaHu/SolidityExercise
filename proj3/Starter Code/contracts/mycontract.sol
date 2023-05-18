// SPDX-License-Identifier: UNLICENSED

// DO NOT MODIFY BELOW THIS
pragma solidity ^0.8.17;

import "hardhat/console.sol";

contract Splitwise {
    // DO NOT MODIFY ABOVE THIS
    // ADD YOUR CONTRACT CODE BELOW

    //uint32[][] public matrix;
    mapping(address => mapping(address => uint32)) matrix;
    mapping(address => bool) public users;
    address[] public all_clients;
    address[] path;
    mapping(address => bool) public visited;


    function user_exists(address key) public view returns (bool) {
        return users[key];
    }

    function lookup(address debtor, address creditor) public view returns (uint32 ret) {
        if (!user_exists(debtor) || !user_exists(creditor)) ret = 0;
        else ret = matrix[debtor][creditor];
    }

    function add_user(address user) private {
        users[user] = true;
        all_clients.push(user);
        require(!visited[user], "I do not know what the heck is going on. ");
    }

    function add_IOU(address creditor, uint32 amount) public {
        address debtor = msg.sender;
        if (!user_exists(debtor)) add_user(debtor);
        if (!user_exists(creditor)) add_user(creditor);
        uint mat_len = all_clients.length;
        path = new address[](mat_len);
        matrix[debtor][creditor] += amount;
        for (uint i = 0; i < mat_len; i++) visited[all_clients[i]] = false;
        uint256 len = find_path(creditor, debtor, 0);
        uint32 curr_min = amount;
        if (len == 1 || len == type(uint256).max || path[len] != debtor) return;
        uint256 next_len = len + 1;
        for (uint i = 0; i <= len; i++) if (curr_min > matrix[path[i]][path[(i + 1) % next_len]]) curr_min = matrix[path[i]][path[(i + 1) % path.length]];
        for (uint i = 0; i <= len; i++) matrix[path[i]][path[(i + 1) % next_len]] -= curr_min;
        delete path;
    }

    function find_path(address curr_vertex, address destination, uint256 curr_idx) private returns (uint) {
        path[curr_idx] = curr_vertex;
        if (curr_vertex == destination) return curr_idx;
        visited[curr_vertex] = true;
        for (uint nxt = 0; nxt < all_clients.length; nxt++) {
            address nxt_vertex = all_clients[nxt];
            if (!visited[nxt_vertex] && matrix[curr_vertex][nxt_vertex] > 0) {
                uint256 result = find_path(nxt_vertex, destination, curr_idx + 1);
                if (result != type(uint256).max) return result;
            }
        }
        return type(uint256).max;
    }


    function get_all_clients() view public returns (address[] memory) {
        return all_clients;
    }


}

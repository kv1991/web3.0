// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BalanceSystem {
    mapping (address => uint) balances;
    address[] public users;

    function increaseBalance(uint balance) public  {
        balances[msg.sender] += balance;
    }

    function transfer(address to, uint _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance.");
        balances[msg.sender] -= _amount;
        balances[to] += _amount;
    }

    function getUserBalance() public view returns (uint){
        return balances[msg.sender];
    }

    function getAllUsers() public view returns(address[] memory) {
       return users;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SpecificAddrWithdraw {
    
    mapping (address => uint256) public balances;
    mapping(address => bool) public whiteList;


    function deposit() public payable {
        balances[msg.sender] += msg.value;
        whiteList[msg.sender] = true;
    }

    modifier onlySpecificAddress() {
        require(whiteList[msg.sender], "Current address can not withdraw.");
        _;
    }

    function withDraw(uint256 amount) public payable onlySpecificAddress {
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getBalacne() public view returns(uint256) {
        return balances[msg.sender];
    }
}
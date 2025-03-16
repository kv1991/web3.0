// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract EtherWallet {
    address payable public immutable owner;
    event log(string funcName, address from, uint256 value, bytes data);

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {
        emit log('receive', msg.sender, msg.value, "");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Not Owner');
        _;
    }

    function withDraw1() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withDraw2() external payable onlyOwner {
        bool success = payable(msg.sender).send(200);
        require(success, 'Send Failed.');
    }

    function withDraw3() external payable onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Send Failed.');
    }

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }
}
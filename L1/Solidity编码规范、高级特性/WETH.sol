// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract WETH {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed delegateAddr, uint256 amount);
    event Deposit(address indexed addr, uint256 amount);
    event WithDraw(uint256 amount);

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withDraw(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit WithDraw(amount);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address delegateAddr, uint256 amount) public returns(bool) {
        allowance[delegateAddr][msg.sender]  = amount;
        emit Approval(delegateAddr, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public payable returns(bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public returns(bool) {
        require(balanceOf[from] >= amount);
        if(from != msg.sender) {
            require(allowance[from][msg.sender] >= amount);
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/ERC20Detailed.sol";
import "@openzeppelin/contracts/ERC20.sol";

contract MyToken is ERC20, ERC20Detailed("My Token", "MT", "4") {
    constructor() public {
        _mint(msg.sender, 1000000000 * 10 ** 4);
    }

    function transferFromOwner(address owner, address recipient, uint256 amount) public returns(bool) {
        return transferFrom(owner, recipient, amount);
    }
}
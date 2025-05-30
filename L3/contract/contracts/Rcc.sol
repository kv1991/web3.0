// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RccToken is ERC20 {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() ERC20("RccToken", "RCCT") {
    _mint(msg.sender, 10000000 * 10 ** decimals());
  }
}
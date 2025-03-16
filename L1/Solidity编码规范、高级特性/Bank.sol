// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Bank {
    address public onwer;
    bool public destoryed;

    event Deposit(address _sender, uint256 amount);
    event DepositeERC20(address indexed sender, address indexed token, uint256 amount);
    event DepositeERC721(address indexed sender, address indexed token, uint256 tokenId);
    event WithdrawnETH(address indexed onwer, uint256 amount);
    event WithdrawERC20(address indexed onwer, address indexed token, uint256 amount);
    event WithdrawERC721(address indexed onwer, address indexed token, uint256 tokenId);
    event ContractDestroyed(address indexed onwer);


    modifier onlyOwner () {
        require(msg.sender == onwer, "Only owner can call this function");
        _;
    }

    modifier notDestoryed() {
        require(!destoryed, 'Contract is destoryed.');
        _;
    }

    constructor() {
        onwer = msg.sender;
    }
    // Deposite ETH
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    // Deposite ERC20
    function depositeERC20(address token, uint256 amount) external notDestoryed {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed.");
        emit DepositeERC20(msg.sender, token, amount);
    }

    // DepositeERC721
    function depositeERC721(address token, uint256 tokenId) external notDestoryed {
        IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);
        emit DepositeERC721(msg.sender, token, tokenId);
    }

    // Withdraw ETH
    function withdrawETH() external onlyOwner notDestoryed {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        (bool success, ) = onwer.call{value: balance}("");
        require(success, "ETH transfer failed");
        emit WithdrawnETH(onwer, balance);
        _destory();
    }

    // Withdraw ERC20
    function withDrawERC20(address token) external onlyOwner notDestoryed {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No ERC20 to withdraw.");
        require(IERC20(token).transfer(onwer, balance), "ERC20 transfer failed.");
        emit WithdrawERC20(onwer, token, balance);
        _destory();
    }

    // Withdraw ERC721
    function withdraw721(address token, uint256 tokenId) external onlyOwner notDestoryed {
        IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);
        emit WithdrawERC721(msg.sender, token, tokenId);
        _destory();
    }

    function _destory() internal {
        destoryed = true;
        emit ContractDestroyed(onwer);
        selfdestruct(payable(msg.sender));
    }
    
}
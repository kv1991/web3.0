// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract CrowFunding {
    uint256 public fundingGoal;
    uint256 public fundingAmount;
    address[] fundersKey;
    address beneficiary;
    bool public AVAILABLED = true;

    mapping (address => uint256 amount) funders;
    mapping (address => bool) private fundersInserted;

    constructor(address _beneficiary, uint256 _fundingGoal) {
        beneficiary = _beneficiary;
        fundingGoal = _fundingGoal;
    }

    modifier needAvailabled() {
        require(AVAILABLED, "CrowFunding is Closed.");
        _;
    }

    function contribute() external payable needAvailabled {
        uint256 potentialFundingAmount = fundingAmount + msg.value;
        if(potentialFundingAmount > fundingGoal) {
            funders[msg.sender] += potentialFundingAmount- fundingGoal;
            fundingAmount += msg.value - fundingGoal;
        } else {
            funders[msg.sender] += msg.value;
            fundingAmount += msg.value;
        }

        // 更新捐赠者信息
        if(!fundersInserted[msg.sender]) {
            fundersInserted[msg.sender] = true;
            fundersKey.push(msg.sender);
        }

        // Refund
        if(potentialFundingAmount > 0) {
            payable(msg.sender).transfer(potentialFundingAmount);
        }
    }

    function close() external returns(bool) {
        if(fundingAmount < fundingGoal) {
            return false;
        }
        uint256 amount = fundingAmount;
        fundingAmount = 0;
        AVAILABLED = false;
        payable(beneficiary).transfer(amount);
        return true;
    }

    function getFundersLength() public view returns(uint256) {
        return fundersKey.length;
    }
}
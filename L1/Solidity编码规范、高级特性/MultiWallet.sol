// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract MultiSigWallet {
    address[] owners;
    uint256 required;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }
    Transaction[] transactions;

    mapping (address => bool) isOwner;
    mapping (uint256 =>  mapping (address => bool)) public approved;

    event Deposite(address indexed sender, uint256 amount);
    event Submit(uint256 indexed idx);
    event Approve(uint256 _txId);
    event Execute(uint256 _txId);
    event Revoke(address sender, uint256 _txId);

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Invalid owners");
        require(_required <= _owners.length, "Invalid required number of owners.");
        for (uint256 i; i < _owners.length; i++) 
        {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner is not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner.");
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "tx doesn't exist.");
        _;
    }

    modifier notApproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], "tx already approved.");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "tx already executed.");
        _;
    }

    receive() external payable {
        emit Deposite(msg.sender, msg.value);
    }

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function submit(address _to, uint256 _value, bytes calldata _data)
    external
    onlyOwner
    returns (uint256)
    {
        transactions.push(Transaction({ to: _to, value: _value, data: _data, executed: false }));
        emit Submit(transactions.length - 1);
        return transactions.length - 1;
    }

    function approve(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approve(_txId);
    }

    function getApprovalCount(uint256 _txId) public view returns(uint256 count) {
        for (uint256 i = 0; i < owners.length; i++) 
        {
            if(approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    function execute(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(getApprovalCount(_txId) > required, "approvals < required");
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed.");
        emit Execute(_txId);
    }

    function revoke(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false; 
        emit Revoke(msg.sender, _txId);
    }
}
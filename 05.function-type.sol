// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FunctionType {
    bytes4 storedSelector;

    function square(uint x) public pure returns(uint) {
        return x * x;
    }
    
    function double(uint x) public pure returns(uint) {
        return 2 * x;
    }

    function executeFunction(bytes4 selector, uint x) external returns(uint z) {
        (bool success, bytes memory data) = address(this).call(abi.encodeWithSelector(selector, x));
        require(success, "Function call failed.");
        z = abi.decode(data, (uint));
    }

    function storeSelector(bytes4 selector) public {
        storedSelector = selector;
    }

    function executeStoredFunction(uint x) public returns (uint) {
        require(storedSelector != bytes4(0), "selector not set.");
        (bool success, bytes memory data) = address(this).call(abi.encodeWithSelector(storedSelector, x));
        require(success, "Fcuntion call faild.");
        return abi.decode(data, (uint));
    }
}
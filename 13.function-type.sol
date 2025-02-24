// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FunctionLearning {
    function publicFunc() public {

    }
    function privateFunc() private {
        
    }
    function externalFunc() external {
        
    }
    function internalFunc() internal {
        
    }

    // 实现一个函数，接受两个参数并返回它们的和与积
    function getPlusAndMultiply(uint x, uint y) public pure returns (uint, uint) {
        return (x + y, x * y);
    }

    function payableFunc() public payable {
        
    }
}

contract C {
    uint public data = 30;
    uint internal iData = 10;
    function x() public returns(uint) {
        data = 3;
        return data;
    }
}

contract Caller {
    C c = new C();
    function f() public view returns (uint) {
        return c.data();
    }
}

contract D is C {
    uint storedData;
    function y() public returns(uint) {
        iData = 3;
        return iData;
    }

    function getResult() public returns(uint) {
        uint a = 1;
        uint b = 2;
        storedData = a + b;
        return storedData;
    }
}

contract ControlTest {
    function testWhile() public pure returns(uint) {
        uint i = 0;
        uint sumOfOdd = 0;
        while (true) {
            i++;
            if(i % 2 == 0) {
                continue;
            }
            if(i > 10) {
                break;
            }
            sumOfOdd += i;
        }
        return sumOfOdd;
    }

    function testFor() public pure returns(uint, uint) {
        uint sumOfOdd = 0;
        uint sumOfEven = 0;
        for (uint i = 0; i < 10; i++) {
            if(i % 2 == 0) {
                sumOfEven += i;
            } else {
                sumOfOdd += i;
            }
        }
        return (sumOfOdd, sumOfEven);
    }
}

contract TryCatchExample {
    function tryCatchDemo(address _contractAddress) public view {
        try ExternalContract(_contractAddress).someFunction() returns (string memory result) {
            // success.
        } catch {
            // error.
        }
    }
}

contract ExternalContract {
    function someFunction() public view returns(string memory) {
        string memory str = "log";
        return str;
    }
}
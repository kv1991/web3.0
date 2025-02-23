// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ReferenceType {
    uint[] data;

    function updateData(uint[] memory newData) public {
        data = newData;
    }

    function getData() public view returns(uint[] memory) {
        return data;
    }

    function modifyStorageData(uint index, uint value) public {
        require(index < data.length, "Index out of bounds");
        data[index] = value;
    }

    function modifyMemoryData(uint[] memory memData) public pure returns(uint[] memory) {
        if(memData.length > 0) {
            memData[0] = 999;
        }
        return memData;
    }
}
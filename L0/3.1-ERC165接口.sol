// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ERC165REG is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping (bytes4 => bool) private _supportedInterfaces;

    constructor() {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

contract TestSupportInterface {
    bytes4 ERC721_Interface_ID = 0x80ac58cd;
    ERC165REG myContract;

    constructor() {
        myContract = new ERC165REG();
    }

    function isSupportInterface() public view returns(bool) {
        return myContract.supportsInterface(ERC721_Interface_ID);
    }
}
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/lib/FvmAddressHelper.sol";
import {FvmAddress} from "../src/structs/FvmAddress.sol";

contract FvmAddressHelperTest is Test {
    using FvmAddressHelper for FvmAddress;

    function test_works() public pure {
        address addr = 0xeC2804Dd9B992C10396b5Af176f06923d984D90e;
        FvmAddress memory fvmAddr = FvmAddressHelper.from(addr);

        address extracted = fvmAddr.extractEvmAddress();
        require(extracted == addr, "addresses not equal");
    }

    function iToHex(bytes memory buffer) internal pure returns (string memory) {
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }
}

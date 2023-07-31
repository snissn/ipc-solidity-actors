// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {FvmAddress} from "../structs/FvmAddress.sol";

struct ValidatorInfo {
    address addr;
    uint256 weight;
    FvmAddress workerAddr;
    string netAddresses;
}

struct ValidatorSet {
    ValidatorInfo[] validators;
    uint64 configurationNumber;
}
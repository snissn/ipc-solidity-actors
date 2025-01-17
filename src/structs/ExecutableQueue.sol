// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.19;

struct ExecutableQueue {
    uint64 genesisEpoch; // genesis epoch
    uint64 period; // number of blocks per epoch
    uint64 first; // next epoch
    uint64 last; // last epoch
    mapping(uint64 => bool) epochs; // epoch => exist
}

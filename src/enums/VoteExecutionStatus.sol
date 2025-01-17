// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.19;

enum VoteExecutionStatus {
    ThresholdNotReached,
    ReachingConsensus,
    RoundAbort,
    ConsensusReached
}

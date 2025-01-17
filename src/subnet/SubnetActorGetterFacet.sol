// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.19;

import {ConsensusType} from "../enums/ConsensusType.sol";
import {Status} from "../enums/Status.sol";
import {BottomUpCheckpoint} from "../structs/Checkpoint.sol";
import {SubnetID} from "../structs/Subnet.sol";
import {ValidatorInfo, ValidatorSet} from "../structs/Validator.sol";
import {CheckpointHelper} from "../lib/CheckpointHelper.sol";
import {SubnetActorStorage} from "../lib/LibSubnetActorStorage.sol";
import {LibVoting} from "../lib/LibVoting.sol";
import {SubnetIDHelper} from "../lib/SubnetIDHelper.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {EnumerableSet} from "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import {FilAddress} from "fevmate/utils/FilAddress.sol";

contract SubnetActorGetterFacet {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SubnetIDHelper for SubnetID;
    using CheckpointHelper for BottomUpCheckpoint;
    using FilAddress for address;
    using Address for address payable;

    // slither-disable-next-line uninitialized-state-variables
    SubnetActorStorage internal s;

    /// @notice get the parent subnet id
    function getParent() external view returns (SubnetID memory) {
        return s.parentId;
    }

    /// @notice get the current status
    function status() external view returns (Status) {
        return s.status;
    }

    /// @notice get the total stake
    function totalStake() external view returns (uint256) {
        return s.totalStake;
    }

    function prevExecutedCheckpointHash() external view returns (bytes32) {
        return s.prevExecutedCheckpointHash;
    }

    function lastVotingExecutedEpoch() external view returns (uint64) {
        return LibVoting.lastVotingExecutedEpoch();
    }

    function executableQueue() external view returns (uint64, uint64, uint64) {
        // slither-disable-next-line unused-return
        return LibVoting.executableQueue();
    }

    function accumulatedRewards(address a) external view returns (uint256) {
        return s.accumulatedRewards[a];
    }

    function stake(address a) external view returns (uint256) {
        return s.stake[a];
    }

    function ipcGatewayAddr() external view returns (address) {
        return s.ipcGatewayAddr;
    }

    function minValidators() external view returns (uint64) {
        return s.minValidators;
    }

    function topDownCheckPeriod() external view returns (uint64) {
        return s.topDownCheckPeriod;
    }

    function bottomUpCheckPeriod() external view returns (uint64) {
        return s.bottomUpCheckPeriod;
    }

    function genesis() external view returns (bytes memory) {
        return s.genesis;
    }

    function majorityPercentage() external view returns (uint64) {
        return LibVoting.majorityPercentage();
    }

    function consensus() external view returns (ConsensusType) {
        return s.consensus;
    }

    function minActivationCollateral() external view returns (uint256) {
        return s.minActivationCollateral;
    }

    function name() external view returns (bytes32) {
        return s.name;
    }

    /// @notice get validator count
    function validatorCount() external view returns (uint256) {
        return s.validators.length();
    }

    /// @notice get validator at index
    /// @param index - the index of the validator set
    function validatorAt(uint256 index) external view returns (address) {
        return s.validators.at(index);
    }

    /// @notice get all the validators in the subnet.
    /// TODO: we can introduce pagination
    function getValidators() external view returns (address[] memory) {
        uint256 length = s.validators.length();
        address[] memory result = new address[](length);

        for (uint256 i = 0; i < length; ) {
            result[i] = s.validators.at(i);
            unchecked {
                ++i;
            }
        }

        return result;
    }

    /// @notice get the full details of the validators, not just their addresses.
    function getValidatorSet() external view returns (ValidatorSet memory) {
        uint256 length = s.validators.length();

        ValidatorInfo[] memory details = new ValidatorInfo[](length);
        address a;

        for (uint256 i = 0; i < length; ) {
            a = s.validators.at(i);
            details[i] = ValidatorInfo({
                addr: a,
                weight: s.stake[a],
                workerAddr: s.validatorWorkerAddresses[a],
                netAddresses: s.validatorNetAddresses[a]
            });
            unchecked {
                ++i;
            }
        }

        return ValidatorSet({validators: details, configurationNumber: s.configurationNumber});
    }

    /// @notice returns the list of registered subnets in IPC
    function listBottomUpCheckpoints(
        uint64 fromEpoch,
        uint64 toEpoch
    ) external view returns (BottomUpCheckpoint[] memory) {
        uint64 period = s.bottomUpCheckPeriod;

        // slither-disable-next-line divide-before-multiply
        uint64 from = (fromEpoch / period) * period;
        // slither-disable-next-line divide-before-multiply
        uint64 to = (toEpoch / period) * period;

        uint64 size = (to - from) / period;
        BottomUpCheckpoint[] memory out = new BottomUpCheckpoint[](size);

        uint64 nextEpoch = from;
        for (uint64 i = 0; i < size; ) {
            out[i] = s.committedCheckpoints[nextEpoch];
            unchecked {
                ++i;
                nextEpoch += period;
            }
        }

        return out;
    }

    /// @notice returns the committed bottom-up checkpoint at specific epoch
    /// @param epoch - the epoch to check
    /// @return exists - whether the checkpoint exists
    /// @return checkpoint - the checkpoint struct
    function bottomUpCheckpointAtEpoch(
        uint64 epoch
    ) public view returns (bool exists, BottomUpCheckpoint memory checkpoint) {
        checkpoint = s.committedCheckpoints[epoch];
        exists = !checkpoint.source.isEmpty();
    }

    /// @notice returns the historical committed bottom-up checkpoint hash
    /// @param epoch - the epoch to check
    /// @return exists - whether the checkpoint exists
    /// @return hash - the hash of the checkpoint
    function bottomUpCheckpointHashAtEpoch(uint64 epoch) external view returns (bool, bytes32) {
        (bool exists, BottomUpCheckpoint memory checkpoint) = bottomUpCheckpointAtEpoch(epoch);
        return (exists, checkpoint.toHash());
    }
}

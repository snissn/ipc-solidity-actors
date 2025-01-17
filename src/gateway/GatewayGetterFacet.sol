// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.19;

import {CrossMsg, BottomUpCheckpoint, StorableMsg} from "../structs/Checkpoint.sol";
import {EpochVoteTopDownSubmission} from "../structs/EpochVoteSubmission.sol";
import {SubnetID, Subnet} from "../structs/Subnet.sol";
import {CheckpointHelper} from "../lib/CheckpointHelper.sol";
import {LibGateway} from "../lib/LibGateway.sol";
import {GatewayActorStorage} from "../lib/LibGatewayActorStorage.sol";
import {LibVoting} from "../lib/LibVoting.sol";
import {SubnetIDHelper} from "../lib/SubnetIDHelper.sol";

contract GatewayGetterFacet {
    // slither-disable-next-line uninitialized-state
    GatewayActorStorage internal s;

    using SubnetIDHelper for SubnetID;
    using CheckpointHelper for BottomUpCheckpoint;

    function crossMsgFee() external view returns (uint256) {
        return s.crossMsgFee;
    }

    function bottomUpNonce() external view returns (uint64) {
        return s.bottomUpNonce;
    }

    function totalSubnets() external view returns (uint64) {
        return s.totalSubnets;
    }

    function minStake() external view returns (uint256) {
        return s.minStake;
    }

    function initialized() external view returns (bool) {
        return s.initialized;
    }

    function bottomUpCheckPeriod() external view returns (uint64) {
        return s.bottomUpCheckPeriod;
    }

    function topDownCheckPeriod() external view returns (uint64) {
        return s.topDownCheckPeriod;
    }

    function getNetworkName() external view returns (SubnetID memory) {
        return s.networkName;
    }

    function bottomUpCheckpoints(uint64 e) external view returns (BottomUpCheckpoint memory) {
        return s.bottomUpCheckpoints[e];
    }

    /// @notice returns the subnet with the given id
    /// @param subnetId the id of the subnet
    /// @return found whether the subnet exists
    /// @return subnet -  the subnet struct
    function getSubnet(SubnetID calldata subnetId) external view returns (bool, Subnet memory) {
        // slither-disable-next-line unused-return
        return LibGateway.getSubnet(subnetId);
    }

    function subnets(bytes32 h) external view returns (Subnet memory subnet) {
        return s.subnets[h];
    }

    /// @notice get number of top-down messages for the given subnet
    function getSubnetTopDownMsgsLength(SubnetID memory subnetId) external view returns (uint256) {
        // slither-disable-next-line unused-return
        (, Subnet storage subnet) = LibGateway.getSubnet(subnetId);
        return subnet.topDownMsgs.length;
    }

    /// @notice get the top-down message at the given index for the given subnet
    function getSubnetTopDownMsg(SubnetID memory subnetId, uint256 index) external view returns (CrossMsg memory) {
        // slither-disable-next-line unused-return
        (, Subnet storage subnet) = LibGateway.getSubnet(subnetId);
        return subnet.topDownMsgs[index];
    }

    /// @notice get the list of top down messages from nonce, we may also consider introducing pagination.
    /// @param subnetId - The subnet id to fetch messages from
    /// @param fromNonce - The starting nonce to get top down messages, inclusive.
    function getTopDownMsgs(SubnetID calldata subnetId, uint64 fromNonce) external view returns (CrossMsg[] memory) {
        (bool registered, Subnet storage subnet) = LibGateway.getSubnet(subnetId);
        if (!registered) {
            return new CrossMsg[](0);
        }

        uint256 totalLength = subnet.topDownMsgs.length;
        uint256 startingNonce = uint256(fromNonce);
        if (startingNonce >= totalLength) {
            return new CrossMsg[](0);
        }

        uint256 msgLength = totalLength - startingNonce;
        CrossMsg[] memory messages = new CrossMsg[](msgLength);
        for (uint256 i = 0; i < msgLength; ) {
            messages[i] = subnet.topDownMsgs[i + startingNonce];
            unchecked {
                ++i;
            }
        }

        return messages;
    }

    /// @notice Get the latest applied top down nonce
    /// @param subnetId - The subnet id to fetch messages from
    function getAppliedTopDownNonce(SubnetID calldata subnetId) external view returns (bool, uint64) {
        (bool registered, Subnet storage subnet) = LibGateway.getSubnet(subnetId);
        if (!registered) {
            return (false, 0);
        }
        return (true, subnet.topDownNonce);
    }

    function totalWeight() public view returns (uint256) {
        return s.totalWeight;
    }

    function appliedTopDownNonce() public view returns (uint64) {
        return s.appliedTopDownNonce;
    }

    function postbox(bytes32 id) public view returns (StorableMsg memory storableMsg, bool wrapped) {
        return (s.postbox[id].message, s.postbox[id].wrapped);
    }

    /// @notice whether a validator has voted for a checkpoint submission during an epoch
    /// @param epoch - the epoch to check
    /// @param submitter - the validator to check
    function hasValidatorVotedForSubmission(uint64 epoch, address submitter) external view returns (bool) {
        EpochVoteTopDownSubmission storage voteSubmission = s.epochVoteSubmissions[epoch];
        return voteSubmission.vote.submitters[voteSubmission.vote.nonce][submitter];
    }

    function getGenesisEpoch() public view returns (uint64) {
        // slither-disable-next-line unused-return
        return LibVoting.getGenesisEpoch();
    }

    function executableQueue() public view returns (uint64, uint64, uint64) {
        // slither-disable-next-line unused-return
        return LibVoting.executableQueue();
    }

    function lastVotingExecutedEpoch() public view returns (uint64) {
        return LibVoting.lastVotingExecutedEpoch();
    }

    function majorityPercentage() public view returns (uint64) {
        return LibVoting.majorityPercentage();
    }

    /// @notice returns the list of registered subnets in IPC
    /// @return subnet - the list of subnets
    function listSubnets() external view returns (Subnet[] memory) {
        uint256 size = s.subnetKeys.length;
        Subnet[] memory out = new Subnet[](size);
        for (uint256 i = 0; i < size; ) {
            bytes32 key = s.subnetKeys[i];
            out[i] = s.subnets[key];
            unchecked {
                ++i;
            }
        }
        return out;
    }
}

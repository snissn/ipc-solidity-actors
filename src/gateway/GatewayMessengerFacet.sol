// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {GatewayActorModifiers} from "../lib/LibGatewayActorStorage.sol";
import {BURNT_FUNDS_ACTOR} from "../constants/Constants.sol";
import {CrossMsg, StorableMsg} from "../structs/Checkpoint.sol";
import {IPCMsgType} from "../enums/IPCMsgType.sol";
import {SubnetID} from "../structs/Subnet.sol";
import {InvalidCrossMsgFromSubnet, NotEnoughFunds, InvalidCrossMsgDstSubnet, CannotSendCrossMsgToItself} from "../errors/IPCErrors.sol";
import {SubnetIDHelper} from "../lib/SubnetIDHelper.sol";
import {LibGateway} from "../lib/LibGateway.sol";
import {StorableMsgHelper} from "../lib/StorableMsgHelper.sol";
import {FilAddress} from "fevmate/utils/FilAddress.sol";

contract GatewayMessengerFacet is GatewayActorModifiers {
    using FilAddress for address payable;
    using SubnetIDHelper for SubnetID;
    using StorableMsgHelper for StorableMsg;

    /// @notice sends an arbitrary cross message from the current subnet to the destination subnet
    /// @param crossMsg - message to send
    function sendCrossMessage(CrossMsg calldata crossMsg) external payable hasFee {
        // There can be many semantics of the (rawAddress, msg.sender) pairs.
        // It depends on who is allowed to call sendCrossMessage method and what we want to get as a result.
        // They can be equal, we can propagate the real sender address only or both.
        // We are going to use the simplest implementation for now and define the appropriate interpretation later
        // based on the business requirements.
        if (crossMsg.message.value != msg.value) {
            revert NotEnoughFunds();
        }

        // We disregard the "to" of the message that will be verified in the _commitCrossMessage().
        // The caller is the one set as the "from" of the message
        if (!crossMsg.message.from.subnetId.equals(s.networkName)) {
            revert InvalidCrossMsgFromSubnet();
        }

        // commit cross-message for propagation
        (bool shouldBurn, bool shouldDistributeRewards) = _commitCrossMessage(crossMsg);

        _crossMsgSideEffects({
            v: crossMsg.message.value,
            toSubnetId: crossMsg.message.to.subnetId.down(s.networkName),
            shouldBurn: shouldBurn,
            shouldDistributeRewards: shouldDistributeRewards
        });
    }

    /// @notice propagates the populated cross net message for the given cid
    /// @param msgCid - the cid of the cross-net message
    function propagate(bytes32 msgCid) external payable hasFee {
        CrossMsg storage crossMsg = s.postbox[msgCid];

        (bool shouldBurn, bool shouldDistributeRewards) = _commitCrossMessage(crossMsg);
        // We must delete the message first to prevent potential re-entrancies,
        // and as the message is deleted and we don't have a reference to the object
        // anymore, we need to pull the data from the message to trigger the side-effects.
        uint256 v = crossMsg.message.value;
        SubnetID memory toSubnetId = crossMsg.message.to.subnetId.down(s.networkName);
        delete s.postbox[msgCid];

        _crossMsgSideEffects({
            v: v,
            toSubnetId: toSubnetId,
            shouldBurn: shouldBurn,
            shouldDistributeRewards: shouldDistributeRewards
        });

        uint256 feeRemainder = msg.value - s.crossMsgFee;

        if (feeRemainder > 0) {
            payable(msg.sender).sendValue(feeRemainder);
        }
    }

    /// @notice Commit the cross message to storage. It outputs a flag signaling
    /// if the committed messages was bottom-up and some funds need to be
    /// burnt or if a top-down message fee needs to be distributed.
    ///
    /// It also validates that destination subnet ID is not empty
    /// and not equal to the current network.
    function _commitCrossMessage(
        CrossMsg memory crossMessage
    ) internal returns (bool shouldBurn, bool shouldDistributeRewards) {
        SubnetID memory to = crossMessage.message.to.subnetId;
        if (to.isEmpty()) {
            revert InvalidCrossMsgDstSubnet();
        }
        // destination is the current network, you are better off with a good old message, no cross needed
        if (to.equals(s.networkName)) {
            revert CannotSendCrossMsgToItself();
        }

        SubnetID memory from = crossMessage.message.from.subnetId;
        IPCMsgType applyType = crossMessage.message.applyType(s.networkName);

        // slither-disable-next-line uninitialized-local
        bool shouldCommitBottomUp;

        if (applyType == IPCMsgType.BottomUp) {
            shouldCommitBottomUp = !to.commonParent(from).equals(s.networkName);
        }

        if (shouldCommitBottomUp) {
            LibGateway.commitBottomUpMsg(crossMessage);

            return (shouldBurn = crossMessage.message.value > 0, shouldDistributeRewards = false);
        }

        if (applyType == IPCMsgType.TopDown) {
            ++s.appliedTopDownNonce;
        }

        LibGateway.commitTopDownMsg(crossMessage);

        return (shouldBurn = false, shouldDistributeRewards = true);
    }

    /// @notice transaction side-effects from the commitment of a cross-net message. It burns funds
    /// and propagates the corresponding rewards.
    /// @param v - the value of the committed cross-net message
    /// @param toSubnetId - the destination subnet of the committed cross-net message
    /// @param shouldBurn - flag if the message should burn funds
    /// @param shouldDistributeRewards - flag if the message should distribute rewards
    function _crossMsgSideEffects(
        uint256 v,
        SubnetID memory toSubnetId,
        bool shouldBurn,
        bool shouldDistributeRewards
    ) internal {
        if (shouldBurn) {
            payable(BURNT_FUNDS_ACTOR).sendValue(v);
        }

        if (shouldDistributeRewards) {
            LibGateway.distributeRewards(toSubnetId.getActor(), s.crossMsgFee);
        }
    }
}

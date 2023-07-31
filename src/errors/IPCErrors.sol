// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

error AlreadyInitialized();
error AlreadyRegisteredSubnet();
error CallerHasNoStake();
error CannotReleaseZero();
error CannotSendCrossMsgToItself();
error CheckpointNotChained();
error CollateralIsZero();
error CollateralStillLockedInSubnet();
error EpochAlreadyExecuted();
error EpochNotVotable();
error GatewayCannotBeZero();
error InconsistentPrevCheckpoint();
error InvalidActorAddress();
error InvalidCheckpointEpoch();
error InvalidCheckpointSource();
error InvalidCrossMsgDestinationSubnet();
error InvalidCrossMsgFromSubnetId();
error InvalidCrossMsgNonce();
error InvalidMajorityPercentage();
error MessageNotSorted();
error MessagesNotSorted();
error NoRewardToWithdraw();
error NoValidatorsInSubnet();
error NotAllValidatorsHaveLeft();
error NotEmptySubnetCircSupply();
error NotEnoughBalance();
error NotEnoughBalanceForRewards();
error NotEnoughFee();
error NotEnoughFunds();
error NotEnoughFundsToRelease();
error NotEnoughSubnetCircSupply();
error NotGateway();
error NotInitialized();
error NotSystemActor();
error NotRegisteredSubnet();
error NotValidator();
error PostboxNotExist();
error SubnetAlreadyKilled();
error SubnetNotActive();
error ValidatorAlreadyVoted();
error ValidatorWeightIsZero();
error ValidatorsAndWeightsLengthMismatch();
error WorkerAddressInvalid();
error WrongCheckpointSource();
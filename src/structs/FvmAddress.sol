// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/*
 * The corresponding implementation of Fil Address from FVM.
 * Currently it supports only f1 addresses.
 * See: https://github.com/filecoin-project/ref-fvm/blob/db8c0b12c801f364e87bda6f52d00c6bd0e1b878/shared/src/address/payload.rs#L87
 */
struct FvmAddress {
    uint8 addrType;
    bytes payload;
}

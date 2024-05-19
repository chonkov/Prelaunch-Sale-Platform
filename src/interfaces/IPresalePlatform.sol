// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPresaleFactory} from "./IPresaleFactory.sol";

interface IPresalePlatform {
    enum PresaleStatus {
        NonExistent,
        Started,
        Liquidity,
        Ended
    }

    // Errors
    error InvalidProtocolFee();
    error InvalidProtocolFeeAddress();
    error InvalidPresaleFactory();

    // Events
    event ProtocolFeeSet(uint256 previousProtocolFee, uint256 newProtocolFee);
    event ProtocolFeeAddressTransferred(address previousProtocolFeeAddress, address newProtocolFeeAddress);
    event ProtocolFeeSet(IPresaleFactory presaleFactory, IPresaleFactory newPresaleFactory);
    event PresaleCreated(address indexed presale, address indexed creator);
    event PresaleEnded(address indexed presale);
    event PresaleLiquidityPhase(address indexed presale);
}

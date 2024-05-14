// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ILaunchpad} from "./interfaces/ILaunchpad.sol";

struct MainLaunchpadInfo {
    uint256 x;
    uint256 y;
}

abstract contract Launchpad is ILaunchpad {
    // Constructor
    constructor(
        MainLaunchpadInfo memory _info,
        uint256 _protocolFee,
        address _protocolFeeAddress,
        address _operator,
        address _factory
    ) {}

    // Modifiers
    modifier onlyOperator() {
        _;
    }
}

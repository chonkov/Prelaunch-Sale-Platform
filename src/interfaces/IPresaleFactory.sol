// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {PresaleMetadata} from "./IPresale.sol";
import {Presale} from "../Presale.sol";

interface IPresaleFactory {
    function createPresale(
        address _owner,
        PresaleMetadata calldata _presaleMetadata,
        uint256 _initSupply,
        uint256 _presalePrice,
        uint64 _startTimestamp,
        uint64 _presaleDuration
    ) external returns (Presale);
}

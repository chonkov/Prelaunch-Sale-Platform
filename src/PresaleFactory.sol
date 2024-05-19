// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import {IPresaleFactory} from "./interfaces/IPresaleFactory.sol";
import {PresaleMetadata} from "./interfaces/IPresale.sol";
import {Presale} from "./Presale.sol";

contract PresaleFactory is IPresaleFactory, Ownable {
    constructor() Ownable(msg.sender) {}

    function createPresale(
        address _owner,
        PresaleMetadata calldata _presaleMetadata,
        uint256 _initSupply,
        uint256 _presalePrice,
        uint64 _startTimestamp,
        uint64 _presaleDuration
    ) external onlyOwner returns (Presale) {
        return new Presale(
            msg.sender, _owner, _presaleMetadata, _initSupply, _presalePrice, _startTimestamp, _presaleDuration
        );
    }
}

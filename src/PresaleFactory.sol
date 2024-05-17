// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import {Presale, PresaleMetadata} from "./Presale.sol";

contract PresaleFactory is Ownable {
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

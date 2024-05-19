// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import {PresaleFactory} from "./PresaleFactory.sol";
import {Presale} from "./Presale.sol";
import {PresaleMetadata} from "./interfaces/IPresale.sol";
import {IPresalePlatform} from "./interfaces/IPresalePlatform.sol";

contract PresalePlatform is IPresalePlatform, Ownable {
    uint32 public protocolFee;
    address public protocolFeeAddress;
    PresaleFactory public presaleFactory;

    mapping(Presale => PresaleStatus) public presaleStatus;

    // Constructor
    constructor(address _owner, uint32 _protocolFee, address _protocolFeeAddress) Ownable(_owner) {
        if (_protocolFee > 10_000) revert();

        protocolFee = _protocolFee;
        protocolFeeAddress = _protocolFeeAddress;
        presaleFactory = new PresaleFactory();
    }

    // External functions
    function createPresale(
        address _owner,
        PresaleMetadata calldata _presaleMetadata,
        uint256 _initSupply,
        uint256 _presalePrice,
        uint64 _startTimestamp,
        uint64 _presaleDuration
    ) external returns (Presale) {
        Presale presale = presaleFactory.createPresale(
            _owner, _presaleMetadata, _initSupply, _presalePrice, _startTimestamp, _presaleDuration
        );
        presaleStatus[presale] = PresaleStatus.Started;

        emit PresaleCreated(address(presale), msg.sender);

        return presale;
    }

    function updatePresale(Presale _presale) external {
        if (_presale.isClaimable()) {
            presaleStatus[_presale] = PresaleStatus.Ended;

            emit PresaleEnded(address(_presale));
        } else if (_presale.isEnded()) {
            presaleStatus[_presale] = PresaleStatus.Liquidity;

            emit PresaleLiquidityPhase(address(_presale));
        }
    }

    // Admin functions
    function setProtocolFee(uint32 newProtocolFee) external onlyOwner {
        if (newProtocolFee == 0) revert InvalidProtocolFee();

        emit ProtocolFeeSet(protocolFee, newProtocolFee);

        protocolFee = newProtocolFee;
    }

    function setProtocolFeeAddress(address newProtocolFeeAddress) external onlyOwner {
        if (newProtocolFeeAddress == address(0)) revert InvalidProtocolFeeAddress();

        emit ProtocolFeeAddressTransferred(protocolFeeAddress, newProtocolFeeAddress);

        protocolFeeAddress = newProtocolFeeAddress;
    }

    function setPresaleFactory(PresaleFactory newPresaleFactory) external onlyOwner {
        if (address(newPresaleFactory) == address(0)) revert InvalidPresaleFactory();

        emit ProtocolFeeSet(presaleFactory, newPresaleFactory);

        presaleFactory = newPresaleFactory;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import {PresaleFactory} from "./PresaleFactory.sol";
import {Presale, PresaleMetadata} from "./Presale.sol";

contract PresalePlatform is Ownable {
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
    event ProtocolFeeSet(PresaleFactory presaleFactory, PresaleFactory newPresaleFactory);
    event PresaleCreated(address indexed presale, address indexed creator);
    event PresaleEnded(address indexed presale);
    event PresaleLiquidityPhase(address indexed presale);

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

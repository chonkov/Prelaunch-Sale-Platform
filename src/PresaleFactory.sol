// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import {Presale, PresaleMetadata} from "./Presale.sol";

contract PresaleFactory is Ownable {
    enum PresaleStatus {
        NonExistent,
        Started,
        Liquidity,
        Ended
    }

    // Errors
    error InvalidProtocolFee(uint256 protocolFee);
    error InvalidProtocolFeeAddress(address protocolFeeAddress);

    // Events
    event ProtocolFeeSet(uint256 previousProtocolFee, uint256 newProtocolFee);
    event ProtocolFeeAddressTransferred(address previousProtocolFeeAddress, address newProtocolFeeAddress);
    event PresaleCreated(address indexed presale, address indexed creator);

    uint32 public protocolFee;
    address public protocolFeeAddress;

    mapping(Presale => PresaleStatus) public presaleStatus;

    // Constructor
    constructor(address _owner, uint32 _protocolFee, address _protocolFeeAddress) Ownable(_owner) {
        if (_protocolFee >= 10_000) revert();

        protocolFee = _protocolFee;
        protocolFeeAddress = _protocolFeeAddress;
    }

    // External functions
    function createPresale(
        address _owner,
        PresaleMetadata calldata _presaleMetadata,
        uint256 _initSupply,
        uint256 _presalePrice,
        uint64 _startTimestamp,
        uint64 _presaleDuration
    ) external {
        Presale presale =
            new Presale(_owner, _presaleMetadata, _initSupply, _presalePrice, _startTimestamp, _presaleDuration);
        presaleStatus[presale] = PresaleStatus.Started;

        emit PresaleCreated(address(presale), msg.sender);
    }

    // Admin functions
    function setProtocolFee(uint32 newProtocolFee) external onlyOwner {
        if (newProtocolFee == 0) revert InvalidProtocolFee(0);

        emit ProtocolFeeSet(protocolFee, newProtocolFee);

        protocolFee = newProtocolFee;
    }

    function setProtocolFeeAddress(address newProtocolFeeAddress) external onlyOwner {
        if (newProtocolFeeAddress == address(0)) revert InvalidProtocolFeeAddress(address(0));

        emit ProtocolFeeAddressTransferred(protocolFeeAddress, newProtocolFeeAddress);

        protocolFeeAddress = newProtocolFeeAddress;
    }
}

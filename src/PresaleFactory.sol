// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import {Presale, PresaleMetadata} from "./Presale.sol";

contract PresaleFactory is Ownable {
    enum PresaleStatus {
        NonExistent,
        Started,
        Ended,
        Claimable
    }

    // Errors
    error InvalidProtocolFee(uint256 protocolFee);
    error InvalidProtocolFeeAddress(address protocolFeeAddress);

    // Events
    event ProtocolFeeSet(uint256 previousProtocolFee, uint256 newProtocolFee);
    event ProtocolFeeAddressTransferred(address previousProtocolFeeAddress, address newProtocolFeeAddress);
    event PresaleCreated(address indexed presale, address indexed creator);

    uint256 public protocolFee;
    address public protocolFeeAddress;

    mapping(Presale => PresaleStatus) public presaleStatus;

    // Constructor
    constructor(address _owner, uint256 _protocolFee, address _protocolFeeAddress) Ownable(_owner) {
        protocolFee = _protocolFee;
        protocolFeeAddress = _protocolFeeAddress;
    }

    // External functions
    function createPresale(
        address _owner,
        PresaleMetadata calldata _presaleMetadata,
        uint256 _initSupply,
        uint256 _price,
        uint128 _startDate,
        uint128 _duration
    ) external {
        Presale presale = new Presale(_owner, _presaleMetadata, _initSupply, _price, _startDate, _duration);
        presaleStatus[presale] = PresaleStatus.Started;

        emit PresaleCreated(address(presale), msg.sender);
    }

    // Admin functions
    function setProtocolFee(uint256 newProtocolFee) external onlyOwner {
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

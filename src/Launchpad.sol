// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ILaunchpad} from "./interfaces/ILaunchpad.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import {Presale} from "./Presale.sol";

struct MainLaunchpadInfo {
    uint256 x;
    uint256 y;
}

error InvalidOperator(address sender);
error InvalidProtocolFee(uint256 protocolFee);
error InvalidProtocolFeeAddress(address protocolFeeAddress);

contract Main {
    event OperatorTransferred(address previousOperator, address newOperator);
    event ProtocolFeeSet(uint256 previousProtocolFee, uint256 newProtocolFee);
    event ProtocolFeeAddressTransferred(address previousProtocolFeeAddress, address newProtocolFeeAddress);

    address public operator;
    uint256 public protocolFee;
    address public protocolFeeAddress;
    PresaleFactory public factory;

    // Constructor
    constructor(MainLaunchpadInfo memory _info, uint256 _protocolFee, address _protocolFeeAddress, address _operator) {
        operator = _operator;
        protocolFee = _protocolFee;
        protocolFeeAddress = _protocolFeeAddress;
        factory = new PresaleFactory(address(this));
    }

    // Modifiers
    modifier onlyOperator() {
        if (msg.sender != operator) revert InvalidOperator(msg.sender);
        _;
    }

    function createPresale() external {
        factory.createPresale();
    }

    /* Operator Functions */
    function setOperator(address newOperator) external onlyOperator {
        if (newOperator == address(0)) revert InvalidOperator(address(0));

        emit OperatorTransferred(operator, newOperator);

        operator = newOperator;
    }

    function setProtocolFee(uint256 newProtocolFee) external onlyOperator {
        if (newProtocolFee == 0) revert InvalidProtocolFee(0);

        emit ProtocolFeeSet(protocolFee, newProtocolFee);

        protocolFee = newProtocolFee;
    }

    function setProtocolFeeAddress(address newProtocolFeeAddress) external onlyOperator {
        if (newProtocolFeeAddress == address(0)) revert InvalidProtocolFeeAddress(address(0));

        emit ProtocolFeeAddressTransferred(protocolFeeAddress, newProtocolFeeAddress);

        protocolFeeAddress = newProtocolFeeAddress;
    }
}

enum PresaleStatus {
    NonExistent,
    Started,
    Ended
}

contract PresaleFactory is Ownable {
    event PresaleCreated(address indexed presale, address indexed creator);

    mapping(address => PresaleStatus) public presaleStatus;

    constructor(address owner) Ownable(owner) {}

    function createPresale() external onlyOwner returns (address) {
        address presale = address(new Presale());
        presaleStatus[presale] = PresaleStatus.Started;

        emit PresaleCreated(presale, msg.sender);

        return presale;
    }
}

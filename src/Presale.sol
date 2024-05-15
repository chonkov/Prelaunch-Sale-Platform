// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

struct PresaleMetadata {
    string name;
    string symbol;
    bytes websiteURL;
    bytes docsURL;
    bytes presaleInfoURL;
}

contract Presale is Ownable, ERC20 {
    error InvalidETHAmount(uint256 amount);

    event PresaleTokensBought(address indexed buyer, uint256 amount, uint256 value);

    bytes public websiteURL;
    bytes public docsURL;
    bytes public presaleInfoURL;

    mapping(address => uint256) public claimableAmounts;
    uint256 initSupply;
    uint256 price;

    constructor(address _owner, PresaleMetadata memory _presaleMetadata, uint256 _initSupply, uint256 _price)
        Ownable(_owner)
        ERC20(_presaleMetadata.name, _presaleMetadata.symbol)
    {
        websiteURL = _presaleMetadata.websiteURL;
        docsURL = _presaleMetadata.docsURL;
        presaleInfoURL = _presaleMetadata.presaleInfoURL;

        initSupply = _initSupply;
        price = _price;
    }

    function buyPresaleToken(uint256 _amount) external payable {
        if (msg.value != _amount * price) revert InvalidETHAmount(msg.value);

        claimableAmounts[msg.sender] += _amount;
        initSupply -= _amount;

        emit PresaleTokensBought(msg.sender, _amount, msg.value);
    }

    function buyToken() external {}

    function isStarted() external view returns (bool) {}
    function isEnded() external view returns (bool) {}
    function isClaimable() external view returns (bool) {}

    //  function transferOperatorOwnership(address newOperator) external;
    //  function updateWhitelist(uint256 _wlBlockNumber, uint256 _wlMinBalance, bytes32 _wlRoot) external;
    //  function increaseHardCap(uint256 _tokenHardCapIncrement) external;
}

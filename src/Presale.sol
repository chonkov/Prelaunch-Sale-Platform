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
    event TokensBought(address indexed buyer, uint256 amount, uint256 value);

    uint256 public constant MAX_PRESALE_DURATION = 14 days;

    bytes public websiteURL;
    bytes public docsURL;
    bytes public presaleInfoURL;

    mapping(address => uint256) public claimableAmounts;
    uint256 initSupply;
    uint256 price;
    uint256 basePrice;

    uint128 startDate;
    uint128 endDate;

    constructor(
        address _owner,
        PresaleMetadata memory _presaleMetadata,
        uint256 _initSupply,
        uint256 _price,
        uint256 _basePrice,
        uint128 _startDate,
        uint128 _duration
    ) Ownable(_owner) ERC20(_presaleMetadata.name, _presaleMetadata.symbol) {
        if (block.timestamp > _startDate) revert();
        if (_duration > MAX_PRESALE_DURATION) revert();

        websiteURL = _presaleMetadata.websiteURL;
        docsURL = _presaleMetadata.docsURL;
        presaleInfoURL = _presaleMetadata.presaleInfoURL;

        initSupply = _initSupply;
        price = _price;
        basePrice = _basePrice;

        startDate = _startDate;
        endDate = _startDate + _duration;
    }

    function buyPresaleToken(uint256 _amount) external payable {
        if (!isStarted() || isEnded()) revert();
        if (msg.value != _amount * basePrice) revert InvalidETHAmount(msg.value);

        claimableAmounts[msg.sender] += _amount;
        initSupply -= _amount;

        emit PresaleTokensBought(msg.sender, _amount, msg.value);
    }

    function buyToken(uint256 _amount) external payable {
        if (!isClaimable()) revert();

        (uint256 curveBasePrice, uint256 curveExtraPrice) = calculatePrice(_amount);
        uint256 price_ = curveBasePrice + curveExtraPrice;
        if (msg.value != price_) revert InvalidETHAmount(msg.value);

        _mint(msg.sender, _amount);

        emit TokensBought(msg.sender, _amount, msg.value);
    }

    function currentPrice() public view returns (uint256) {
        return basePrice + (price * totalSupply() / 10 ** decimals());
    }

    function calculatePrice(uint256 amount) public view returns (uint256 curveBasePrice, uint256 curveExtraPrice) {
        uint256 _currentPrice = currentPrice();
        curveBasePrice = ((amount * _currentPrice)) / 10 ** decimals();
        curveExtraPrice = (((amount * price) / 10 ** decimals()) * (amount)) / (2 * 10 ** decimals());
    }

    function isStarted() public view returns (bool) {}
    function isEnded() public view returns (bool) {}
    function isClaimable() public view returns (bool) {}

    //  function transferOperatorOwnership(address newOperator) external;
    //  function updateWhitelist(uint256 _wlBlockNumber, uint256 _wlMinBalance, bytes32 _wlRoot) external;
    //  function increaseHardCap(uint256 _tokenHardCapIncrement) external;
}

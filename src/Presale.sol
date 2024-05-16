// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {IUniswapV2Factory, IUniswapV2Pair} from "./interfaces/IUniswapV2.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {PresaleFactory} from "./PresaleFactory.sol";

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
    event InitSupplyIncreased(uint256 amount);

    uint256 public constant MAX_PRESALE_DURATION = 28 days;
    uint256 public constant LIQUIDITY_PHASE_DURATION = 14 days;
    address public constant UNISWAP_FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public presaleFactory;

    bytes public websiteURL;
    bytes public docsURL;
    bytes public presaleInfoURL;

    mapping(address => uint256) public claimableAmounts;
    uint256 public initSupply;
    uint256 public totalSupplyPresale;
    uint256 public price;
    uint256 public immutable presalePrice;

    uint128 startTimestamp;
    uint128 endTimestamp;

    constructor(
        address _owner,
        PresaleMetadata memory _presaleMetadata,
        uint256 _initSupply,
        uint256 _presalePrice,
        uint128 _startTimestamp,
        uint128 _duration
    ) Ownable(_owner) ERC20(_presaleMetadata.name, _presaleMetadata.symbol) {
        if (block.timestamp > _startTimestamp) revert();
        if (_duration > MAX_PRESALE_DURATION) revert();

        presaleFactory = msg.sender;

        websiteURL = _presaleMetadata.websiteURL;
        docsURL = _presaleMetadata.docsURL;
        presaleInfoURL = _presaleMetadata.presaleInfoURL;

        initSupply = _initSupply;
        presalePrice = _presalePrice;

        startTimestamp = _startTimestamp;
        endTimestamp = _startTimestamp + _duration;
    }

    function endPresale() external {
        if (initSupply == 0) endTimestamp = uint128(block.timestamp);
    }

    function buyPresaleToken(uint256 _amount) external payable {
        if (!isStarted() || isEnded()) revert();
        if (msg.value != _amount * presalePrice) revert InvalidETHAmount(msg.value);

        claimableAmounts[msg.sender] += _amount;
        totalSupplyPresale += _amount;
        initSupply -= _amount;

        emit PresaleTokensBought(msg.sender, _amount, msg.value);
    }

    function buyToken(uint256 _amount) external payable {
        if (!isClaimable()) revert();

        if (msg.value != _amount * price) revert InvalidETHAmount(msg.value);

        _mint(msg.sender, _amount);

        emit TokensBought(msg.sender, _amount, msg.value);
    }

    function isStarted() public view returns (bool) {
        return block.timestamp >= startTimestamp;
    }

    function isEnded() public view returns (bool) {
        return block.timestamp >= endTimestamp;
    }

    function isClaimable() public view returns (bool) {
        return block.timestamp >= endTimestamp + LIQUIDITY_PHASE_DURATION;
    }

    function createLiquidityPool() external onlyOwner {
        uint256 totalSupplyPresale_ = totalSupplyPresale;
        uint256 totalFundsRaised = totalSupplyPresale_ * presalePrice;

        uint256 fundsReservedForPlatform = totalFundsRaised * PresaleFactory(presaleFactory).protocolFee();
        totalFundsRaised -= fundsReservedForPlatform;

        address pair = IUniswapV2Factory(UNISWAP_FACTORY_ADDRESS).createPair(WETH_ADDRESS, address(this));
        require(pair == IUniswapV2Factory(UNISWAP_FACTORY_ADDRESS).getPair(WETH_ADDRESS, address(this)));

        IWETH(WETH_ADDRESS).deposit{value: totalFundsRaised}();
        uint256 wethBalance = IWETH(WETH_ADDRESS).balanceOf(address(this));
        require(wethBalance == totalFundsRaised);

        IWETH(WETH_ADDRESS).transfer(pair, wethBalance);
        _mint(pair, totalFundsRaised / (presalePrice * 2)); // mint two times less tokens, therefore doubling the price
        IUniswapV2Pair(pair).mint(owner());

        (bool success,) = PresaleFactory(presaleFactory).protocolFeeAddress().call{value: fundsReservedForPlatform}("");
        if (!success) revert();
    }

    function increaseInitSupply(uint256 _amount) external onlyOwner {
        initSupply += _amount;

        emit InitSupplyIncreased(_amount);
    }
}

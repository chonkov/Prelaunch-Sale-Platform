// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {IUniswapV2Factory, IUniswapV2Pair} from "./interfaces/IUniswapV2.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {PresalePlatform} from "./PresalePlatform.sol";

struct PresaleMetadata {
    string name;
    string symbol;
    bytes websiteURL;
    bytes docsURL;
    bytes presaleInfoURL;
}

contract Presale is Ownable, ERC20 {
    // Errors
    error InvalidETHAmount(uint256 amount);
    error InvalidFunctionParameter();
    error BuyingPresaleTokensDisallowed();
    error BuyingTokensDisallowed();
    error ClaimingTokensDisallowed();
    error InvalidAmount();
    error PoolCreationDisallowed();
    error PresaleHasNotEnded();
    error AlreadyCreatedPool();
    error AlreadyTerminated();
    error UnsuccessfulExternalCall();

    // Events
    event PresaleTokensBought(address indexed buyer, uint256 amount, uint256 value);
    event TokensBought(address indexed buyer, uint256 amount, uint256 value);
    event TokensCLaimed(address indexed claimer, uint256 amount);
    event TokensRedeemed(address indexed redemmer, uint256 amount);
    event InitSupplyIncreased(uint256 amount);
    event WebsiteURLChanged(bytes websiteURL, bytes newWebsiteURL);
    event DocsURLChanged(bytes docsURL, bytes newDocsURL);
    event PresaleInfoURLChanged(bytes presaleInfoURL, bytes newPresaleInfoURL);
    event PresaleEndedPrematurely(uint256 timestamp);
    event LiqidityPoolCreated(address indexed pair);
    event PresaleTerminated();

    uint256 public constant MAX_PRESALE_DURATION = 28 days;
    uint256 public constant MAX_LIQUIDITY_PHASE_DURATION = 14 days;
    uint256 public VESTING_PERIOD = 10 days;

    address public constant UNISWAP_FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    PresalePlatform public presalePlatform;

    bytes public websiteURL;
    bytes public docsURL;
    bytes public presaleInfoURL;

    mapping(address => uint256) public claimableAmounts;
    mapping(address => uint256) public claimedAmounts;
    uint256 public initSupply;
    uint256 public totalSupplyPresale;
    uint256 public immutable presalePrice;

    bool public isPoolCreated;
    bool public isTerminated;

    uint64 public startTimestamp;
    uint64 public endTimestamp;

    constructor(
        address _presalePlatform,
        address _owner,
        PresaleMetadata memory _presaleMetadata,
        uint256 _initSupply,
        uint256 _presalePrice,
        uint64 _startTimestamp,
        uint64 _presaleDuration
    ) Ownable(_owner) ERC20(_presaleMetadata.name, _presaleMetadata.symbol) {
        if (block.timestamp > _startTimestamp) revert InvalidFunctionParameter();
        if (_presaleDuration > MAX_PRESALE_DURATION) revert InvalidFunctionParameter();

        presalePlatform = PresalePlatform(_presalePlatform);

        websiteURL = _presaleMetadata.websiteURL;
        docsURL = _presaleMetadata.docsURL;
        presaleInfoURL = _presaleMetadata.presaleInfoURL;

        initSupply = _initSupply;
        presalePrice = _presalePrice;

        startTimestamp = _startTimestamp;
        endTimestamp = _startTimestamp + _presaleDuration;
    }

    function endPresalePrematurely() external {
        if (initSupply != 0) revert();
        endTimestamp = uint64(block.timestamp);

        emit PresaleEndedPrematurely(block.timestamp);
    }

    function buyPresaleToken(uint256 _amount) external payable {
        if (!isStarted() || isEnded()) revert BuyingPresaleTokensDisallowed();
        if (msg.value != _amount * presalePrice) revert InvalidETHAmount(msg.value);

        claimableAmounts[msg.sender] += _amount;
        totalSupplyPresale += _amount;
        initSupply -= _amount;

        emit PresaleTokensBought(msg.sender, _amount, msg.value);
    }

    function buyToken(uint256 _amount) external payable {
        if (!isClaimable() || isTerminated || !isPoolCreated) revert BuyingTokensDisallowed();

        if (msg.value != _amount * presalePrice * 2) revert InvalidETHAmount(msg.value);

        _mint(msg.sender, _amount);

        emit TokensBought(msg.sender, _amount, msg.value);
    }

    function claimTokens(uint256 _amount) external {
        if (!isClaimable() || isTerminated || !isPoolCreated) revert ClaimingTokensDisallowed();

        uint256 timeElapsed = block.timestamp - (endTimestamp + MAX_LIQUIDITY_PHASE_DURATION);
        uint256 claimableAmount = timeElapsed * (claimableAmounts[msg.sender] + claimedAmounts[msg.sender])
            / VESTING_PERIOD - claimedAmounts[msg.sender];

        if (_amount > claimableAmount) revert InvalidAmount();

        claimableAmounts[msg.sender] -= _amount;
        claimedAmounts[msg.sender] += _amount;

        _mint(msg.sender, _amount);

        emit TokensCLaimed(msg.sender, _amount);
    }

    function redeem() external {
        if (!isClaimable() || isPoolCreated) revert();

        uint256 amount = claimableAmounts[msg.sender];
        uint256 value = amount * presalePrice;

        delete claimableAmounts[msg.sender];

        emit TokensRedeemed(msg.sender, amount);

        (bool success,) = msg.sender.call{value: value}("");
        if (!success) revert UnsuccessfulExternalCall();
    }

    function isStarted() public view returns (bool) {
        return block.timestamp >= startTimestamp;
    }

    function isEnded() public view returns (bool) {
        return block.timestamp >= endTimestamp;
    }

    function isClaimable() public view returns (bool) {
        return block.timestamp >= endTimestamp + MAX_LIQUIDITY_PHASE_DURATION;
    }

    // Admin functions
    function createLiquidityPool() external onlyOwner {
        if (!isEnded() || isPoolCreated || isTerminated) revert PoolCreationDisallowed();

        isPoolCreated = true;

        uint256 totalFundsRaised = totalSupplyPresale * presalePrice;

        uint256 fundsReservedForPlatform = totalFundsRaised * PresalePlatform(presalePlatform).protocolFee() / 10_000;
        totalFundsRaised -= fundsReservedForPlatform;

        address pair = IUniswapV2Factory(UNISWAP_FACTORY_ADDRESS).createPair(WETH_ADDRESS, address(this));
        require(pair == IUniswapV2Factory(UNISWAP_FACTORY_ADDRESS).getPair(WETH_ADDRESS, address(this)));

        IWETH(WETH_ADDRESS).deposit{value: totalFundsRaised}();
        uint256 wethBalance = IWETH(WETH_ADDRESS).balanceOf(address(this));
        require(wethBalance == totalFundsRaised);

        IWETH(WETH_ADDRESS).transfer(pair, wethBalance);
        _mint(pair, totalFundsRaised / (presalePrice * 2)); // mint two times less tokens, therefore doubling the price
        IUniswapV2Pair(pair).mint(owner());

        (bool success,) =
            PresalePlatform(presalePlatform).protocolFeeAddress().call{value: fundsReservedForPlatform}("");
        if (!success) revert UnsuccessfulExternalCall();

        emit LiqidityPoolCreated(pair);
    }

    function terminatePresale() external onlyOwner {
        if (!isEnded()) revert PresaleHasNotEnded();
        if (isPoolCreated) revert AlreadyCreatedPool();
        if (isTerminated) revert AlreadyTerminated();

        isTerminated = true;

        emit PresaleTerminated();
    }

    function setWebsiteURL(bytes calldata _websiteURL) external onlyOwner {
        emit WebsiteURLChanged(websiteURL, _websiteURL);

        websiteURL = _websiteURL;
    }

    function setDocsURL(bytes calldata _docsURL) external onlyOwner {
        emit DocsURLChanged(docsURL, _docsURL);

        docsURL = _docsURL;
    }

    function setPresaleInfoURL(bytes calldata _presaleInfoURL) external onlyOwner {
        emit PresaleInfoURLChanged(presaleInfoURL, _presaleInfoURL);

        presaleInfoURL = _presaleInfoURL;
    }
}

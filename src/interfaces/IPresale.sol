// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

struct PresaleMetadata {
    string name;
    string symbol;
    bytes websiteURL;
    bytes docsURL;
    bytes presaleInfoURL;
}

interface IPresale {
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

    function endPresalePrematurely() external;

    function buyPresaleToken(uint256 _amount) external payable;

    function buyToken(uint256 _amount) external payable;

    function claimTokens(uint256 _amount) external;

    function redeem() external;

    function isStarted() external view returns (bool);

    function isEnded() external view returns (bool);

    function isClaimable() external view returns (bool);

    // Admin functions
    function createLiquidityPool() external;

    function terminatePresale() external;

    function setWebsiteURL(bytes calldata _websiteURL) external;

    function setDocsURL(bytes calldata _docsURL) external;

    function setPresaleInfoURL(bytes calldata _presaleInfoURL) external;
}

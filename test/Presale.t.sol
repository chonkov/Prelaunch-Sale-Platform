// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {PresaleFactory} from "../src/PresaleFactory.sol";
import {PresalePlatform} from "../src/PresalePlatform.sol";
import {Presale, PresaleMetadata} from "../src/Presale.sol";
import {IPresale} from "../src/interfaces/IPresale.sol";

contract MockPresalePlatform {
    uint32 public protocolFee = 1_000;
    address public protocolFeeAddress = msg.sender;

    function setProtocolFeeAddress(address _protocolFeeAddress) external {
        protocolFeeAddress = _protocolFeeAddress;
    }
}

contract PresaleTest is Test {
    MockPresalePlatform platform;
    Presale presale;
    PresaleMetadata metadata;

    address owner = address(123); // owner of `Presale`
    address user1 = address(456);
    address user2 = address(789);

    uint256 initSupply = 1_000;
    uint256 presalePrice = 0.1 ether;
    uint64 duration = 100;

    function setUp() public {
        platform = new MockPresalePlatform();
        metadata = PresaleMetadata("Presale Token", "PST", "", "", "");

        presale = new Presale(
            address(platform), owner, metadata, initSupply, presalePrice, uint64(block.timestamp + 1), duration
        );
        vm.deal(user1, 100e18);
        vm.deal(user2, 100e18);
    }

    function testSetUp() public view {
        assertEq(address(presale.presalePlatform()), address(platform));
        assertEq(presale.websiteURL(), "");
        assertEq(presale.docsURL(), "");
        assertEq(presale.presaleInfoURL(), "");

        assertEq(presale.initSupply(), initSupply);
        assertEq(presale.totalSupplyPresale(), 0);
        assertEq(presale.presalePrice(), presalePrice);

        assertEq(presale.isStarted(), false);
        assertEq(presale.isEnded(), false);
        assertEq(presale.isClaimable(), false);
        assertEq(presale.isPoolCreated(), false);
        assertEq(presale.isTerminated(), false);

        assertEq(presale.startTimestamp(), block.timestamp + 1);
        assertEq(presale.endTimestamp(), block.timestamp + 1 + duration);
    }

    function testBuyPresaleToken() public {
        vm.warp(block.timestamp + 1);

        uint256 amount = 100;

        assertEq(presale.initSupply(), initSupply);
        assertEq(presale.totalSupplyPresale(), 0);
        assertEq(presale.claimableAmounts(user1), 0);

        vm.prank(user1);
        presale.buyPresaleToken{value: amount * presalePrice}(amount);

        assertEq(presale.initSupply(), initSupply - amount);
        assertEq(presale.totalSupplyPresale(), amount);
        assertEq(presale.claimableAmounts(user1), amount);

        vm.prank(user2);
        presale.buyPresaleToken{value: amount * presalePrice}(amount);

        assertEq(presale.initSupply(), initSupply - amount * 2);
        assertEq(presale.totalSupplyPresale(), amount * 2);
        assertEq(presale.claimableAmounts(user2), amount);
    }

    function testBuyPresaleTokenFail() public {
        uint256 amount = 100;

        vm.prank(user1);
        vm.expectRevert(IPresale.BuyingPresaleTokensDisallowed.selector);
        presale.buyPresaleToken{value: amount * presalePrice}(amount);

        vm.warp(block.timestamp + 1);
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IPresale.InvalidETHAmount.selector, 10e18 + 1));
        presale.buyPresaleToken{value: amount * presalePrice + 1}(amount);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IPresale.InvalidETHAmount.selector, 10e18 - 1));
        presale.buyPresaleToken{value: amount * presalePrice - 1}(amount);

        vm.warp(block.timestamp + 101);

        vm.prank(user1);
        vm.expectRevert(IPresale.BuyingPresaleTokensDisallowed.selector);
        presale.buyPresaleToken{value: amount * presalePrice}(amount);
    }

    function testBuyToken() public {
        assertEq(presale.isPoolCreated(), false);

        bytes32 slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 | bytes32(uint256(1));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        assertEq(presale.isPoolCreated(), true);

        assertEq(presale.totalSupply(), 0);
        assertEq(presale.balanceOf(user1), 0);

        uint256 amount = 100;
        vm.warp(block.timestamp + 101 + 14 days);

        vm.prank(user1);
        presale.buyToken{value: amount * presalePrice * 2}(amount);

        assertEq(presale.totalSupply(), 100);
        assertEq(presale.balanceOf(user1), 100);
        assertEq(presale.initSupply(), initSupply);
    }

    function testBuyTokenFail() public {
        uint256 amount = 100;
        vm.warp(block.timestamp + 1);

        // `isClaimable` - false
        vm.prank(user1);
        vm.expectRevert(IPresale.BuyingTokensDisallowed.selector);
        presale.buyToken{value: amount * presalePrice * 2}(amount);

        vm.warp(block.timestamp + 101 + 14 days);

        assertEq(presale.isTerminated(), false);

        // `isTerminated` - true
        bytes32 slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 | bytes32(uint256(256));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        assertEq(presale.isTerminated(), true);

        vm.prank(user1);
        vm.expectRevert(IPresale.BuyingTokensDisallowed.selector);
        presale.buyToken{value: amount * presalePrice * 2}(amount);

        // `isPoolCreated` - false
        slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 ^ bytes32(uint256(256));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        vm.prank(user1);
        vm.expectRevert(IPresale.BuyingTokensDisallowed.selector);
        presale.buyToken{value: amount * presalePrice * 2}(amount);

        // `isClaimable` - true
        // `isTerminated` - false
        // `isPoolCreated` - true
        // `ValidETHAmount` - false
        slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 | bytes32(uint256(1));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IPresale.InvalidETHAmount.selector, amount * presalePrice * 2 + 1));
        presale.buyToken{value: amount * presalePrice * 2 + 1}(amount);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IPresale.InvalidETHAmount.selector, amount * presalePrice * 2 - 1));
        presale.buyToken{value: amount * presalePrice * 2 - 1}(amount);
    }

    function testClaimTokens() public {
        uint256 amount = 100;
        vm.warp(block.timestamp + 1);

        vm.prank(user1);
        presale.buyPresaleToken{value: amount * presalePrice}(amount);

        bytes32 slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 | bytes32(uint256(1));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        // We wait for one more day to pass, before we claim
        vm.warp(block.timestamp + 101 + 14 days + 1 days);

        vm.prank(user1);
        vm.expectRevert(IPresale.InvalidAmount.selector);
        presale.claimTokens(11);

        assertEq(presale.claimableAmounts(user1), 100);
        assertEq(presale.claimedAmounts(user1), 0);
        assertEq(presale.totalSupply(), 0);
        assertEq(presale.balanceOf(user1), 0);

        vm.prank(user1);
        presale.claimTokens(10);

        assertEq(presale.claimableAmounts(user1), 90);
        assertEq(presale.claimedAmounts(user1), 10);
        assertEq(presale.totalSupply(), 10);
        assertEq(presale.balanceOf(user1), 10);
    }

    function testClaimTokensFail() public {
        uint256 amount = 100;
        vm.warp(block.timestamp + 1);

        vm.prank(user1);
        presale.buyPresaleToken{value: amount * presalePrice}(amount);

        vm.prank(user1);
        vm.expectRevert(IPresale.ClaimingTokensDisallowed.selector);
        presale.claimTokens(0);

        vm.warp(block.timestamp + 101 + 14 days);

        bytes32 slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 | bytes32(uint256(256));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        vm.prank(user1);
        vm.expectRevert(IPresale.ClaimingTokensDisallowed.selector);
        presale.claimTokens(0);

        slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 ^ bytes32(uint256(256));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        vm.prank(user1);
        vm.expectRevert(IPresale.ClaimingTokensDisallowed.selector);
        presale.claimTokens(0);

        slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 | bytes32(uint256(1));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        vm.prank(user1);
        vm.expectRevert(IPresale.InvalidAmount.selector);
        presale.claimTokens(1);
    }

    function testRedeem() public {
        uint256 amount = 100;

        platform.setProtocolFeeAddress(owner);

        vm.warp(block.timestamp + 1);

        vm.prank(user1);
        presale.buyPresaleToken{value: amount * presalePrice}(amount);

        vm.warp(block.timestamp + 101 + 14 days);

        assertEq(presale.claimableAmounts(user1), 100);
        assertEq(user1.balance, 90e18);

        vm.prank(user1);
        presale.redeem();

        assertEq(presale.claimableAmounts(user1), 0);
        assertEq(user1.balance, 100e18);
    }

    function testRedeemFail() public {
        vm.prank(user1);
        vm.expectRevert();
        presale.redeem();

        vm.warp(block.timestamp + 101 + 14 days);

        bytes32 slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 | bytes32(uint256(1));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        vm.prank(user1);
        vm.expectRevert();
        presale.redeem();

        slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 ^ bytes32(uint256(1));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        platform.setProtocolFeeAddress(address(this));

        vm.expectRevert(IPresale.UnsuccessfulExternalCall.selector);
        presale.redeem();
    }

    function testEndPresalePrematurely() public {
        uint256 amount = 1_000;
        vm.warp(block.timestamp + 1);

        vm.prank(user1);
        presale.buyPresaleToken{value: amount * presalePrice}(amount);

        vm.prank(owner);
        vm.expectRevert();
        presale.terminatePresale();

        vm.prank(owner);
        presale.endPresalePrematurely();

        vm.prank(owner);
        presale.terminatePresale();
    }

    function testEndPresalePrematurelyFail() public {
        uint256 amount = 999;
        vm.warp(block.timestamp + 1);

        vm.prank(user1);
        presale.buyPresaleToken{value: amount * presalePrice}(amount);

        vm.prank(owner);
        vm.expectRevert();
        presale.endPresalePrematurely();
    }

    function testSetWebsiteURL() public {
        vm.prank(owner);
        presale.setWebsiteURL("");
    }

    function testSetWebsiteURLFail() public {
        vm.prank(user1);
        vm.expectRevert();
        presale.setWebsiteURL("");
    }

    function testSetDocsURL() public {
        vm.prank(owner);
        presale.setDocsURL("");
    }

    function testSetDocsURLFail() public {
        vm.prank(user1);
        vm.expectRevert();
        presale.setDocsURL("");
    }

    function testSetPresaleInfoURL() public {
        vm.prank(owner);
        presale.setPresaleInfoURL("");
    }

    function testSetPresaleInfoURLFail() public {
        vm.prank(user1);
        vm.expectRevert();
        presale.setPresaleInfoURL("");
    }

    function testCreateLiquidityPool() public {
        uint256 amount = 100;

        platform.setProtocolFeeAddress(owner);

        vm.warp(block.timestamp + 1);

        vm.prank(user1);
        presale.buyPresaleToken{value: amount * presalePrice}(amount);

        vm.warp(block.timestamp + 101);

        assertEq(presale.isPoolCreated(), false);

        vm.prank(owner);
        presale.createLiquidityPool();

        assertEq(presale.isPoolCreated(), true);
    }

    function testCreateLiquidityPoolFail() public {
        uint256 amount = 100;

        vm.warp(block.timestamp + 1);

        vm.prank(user1);
        presale.buyPresaleToken{value: amount * presalePrice}(amount);

        vm.expectRevert();
        presale.createLiquidityPool();

        vm.prank(owner);
        vm.expectRevert(IPresale.PoolCreationDisallowed.selector);
        presale.createLiquidityPool();

        vm.warp(block.timestamp + 101);

        bytes32 slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 | bytes32(uint256(1));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        vm.prank(owner);
        vm.expectRevert(IPresale.PoolCreationDisallowed.selector);
        presale.createLiquidityPool();

        slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 ^ bytes32(uint256(1));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 | bytes32(uint256(256));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        vm.prank(owner);
        vm.expectRevert(IPresale.PoolCreationDisallowed.selector);
        presale.createLiquidityPool();

        slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 ^ bytes32(uint256(256));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        platform.setProtocolFeeAddress(address(this));

        vm.prank(owner);
        vm.expectRevert(IPresale.UnsuccessfulExternalCall.selector);
        presale.createLiquidityPool();
    }

    function testTerminatePresale() public {
        uint256 amount = 100;

        vm.warp(block.timestamp + 1);

        vm.prank(user1);
        presale.buyPresaleToken{value: amount * presalePrice}(amount);

        vm.warp(block.timestamp + 101);

        assertEq(presale.isTerminated(), false);

        vm.prank(owner);
        presale.terminatePresale();

        assertEq(presale.isTerminated(), true);
    }

    function testTerminatePresaleFail() public {
        uint256 amount = 100;

        vm.warp(block.timestamp + 1);

        vm.prank(user1);
        presale.buyPresaleToken{value: amount * presalePrice}(amount);

        vm.expectRevert();
        presale.terminatePresale();

        vm.prank(owner);
        vm.expectRevert(IPresale.PresaleHasNotEnded.selector);
        presale.terminatePresale();

        vm.warp(block.timestamp + 101);

        bytes32 slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 | bytes32(uint256(1));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        vm.prank(owner);
        vm.expectRevert(IPresale.AlreadyCreatedPool.selector);
        presale.terminatePresale();

        slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 ^ bytes32(uint256(1));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        vm.prank(owner);
        presale.terminatePresale();

        vm.prank(owner);
        vm.expectRevert(IPresale.AlreadyTerminated.selector);
        presale.terminatePresale();
    }
}

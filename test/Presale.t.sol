// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {PresaleFactory} from "../src/PresaleFactory.sol";
import {PresalePlatform} from "../src/PresalePlatform.sol";
import {Presale, PresaleMetadata} from "../src/Presale.sol";

contract MockPresalePlatform {
    uint32 public protocolFee = 1_000;
    address public protocolFeeAddress = msg.sender;
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
        vm.warp(2);

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
        vm.expectRevert(Presale.BuyingPresaleTokensDisallowed.selector);
        presale.buyPresaleToken{value: amount * presalePrice}(amount);

        vm.warp(2);
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Presale.InvalidETHAmount.selector, 10e18 + 1));
        presale.buyPresaleToken{value: amount * presalePrice + 1}(amount);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Presale.InvalidETHAmount.selector, 10e18 - 1));
        presale.buyPresaleToken{value: amount * presalePrice - 1}(amount);

        vm.warp(102);

        vm.prank(user1);
        vm.expectRevert(Presale.BuyingPresaleTokensDisallowed.selector);
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
        vm.warp(102 + 14 days);

        vm.prank(user1);
        presale.buyToken{value: amount * presalePrice * 2}(amount);

        assertEq(presale.totalSupply(), 100);
        assertEq(presale.balanceOf(user1), 100);
        assertEq(presale.initSupply(), initSupply);
    }

    function testBuyTokenFail() public {
        uint256 amount = 100;
        vm.warp(2);

        // `isClaimable` - false
        vm.prank(user1);
        vm.expectRevert(Presale.BuyingTokensDisallowed.selector);
        presale.buyToken{value: amount * presalePrice * 2}(amount);

        vm.warp(102 + 14 days);

        assertEq(presale.isTerminated(), false);

        // `isTerminated` - true
        bytes32 slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 | bytes32(uint256(256));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        assertEq(presale.isTerminated(), true);

        vm.prank(user1);
        vm.expectRevert(Presale.BuyingTokensDisallowed.selector);
        presale.buyToken{value: amount * presalePrice * 2}(amount);

        // `isPoolCreated` - false
        slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 ^ bytes32(uint256(256));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        vm.prank(user1);
        vm.expectRevert(Presale.BuyingTokensDisallowed.selector);
        presale.buyToken{value: amount * presalePrice * 2}(amount);

        // `isClaimable` - true
        // `isTerminated` - false
        // `isPoolCreated` - true
        // `ValidETHAmount` - false
        slot15 = vm.load(address(presale), bytes32(uint256(15)));
        slot15 = slot15 | bytes32(uint256(1));
        vm.store(address(presale), bytes32(uint256(15)), slot15);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Presale.InvalidETHAmount.selector, amount * presalePrice * 2 + 1));
        presale.buyToken{value: amount * presalePrice * 2 + 1}(amount);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Presale.InvalidETHAmount.selector, amount * presalePrice * 2 - 1));
        presale.buyToken{value: amount * presalePrice * 2 - 1}(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {PresalePlatform} from "../src/PresalePlatform.sol";
import {Presale, PresaleMetadata} from "../src/Presale.sol";
import {PresaleFactory} from "../src/PresaleFactory.sol";

contract PresalePlatformTest is Test {
    PresalePlatform platform;
    address platformOwner = address(123);
    uint16 protocolFee = 1_000;
    address user = address(456);
    PresaleMetadata metadata;

    function setUp() public {
        platform = new PresalePlatform(platformOwner, protocolFee, platformOwner);
    }

    function testSetProtocolFeeFail() public {
        vm.expectRevert();
        platform.setProtocolFee(protocolFee);

        vm.prank(platformOwner);
        vm.expectRevert(PresalePlatform.InvalidProtocolFee.selector);
        platform.setProtocolFee(0);
    }

    function testSetProtocolFee() public {
        vm.prank(platformOwner);
        platform.setProtocolFee(protocolFee + 1);
    }

    function testSetProtocolFeeAddressFail() public {
        vm.expectRevert();
        platform.setProtocolFeeAddress(platformOwner);

        vm.prank(platformOwner);
        vm.expectRevert(PresalePlatform.InvalidProtocolFeeAddress.selector);
        platform.setProtocolFeeAddress(address(0));
    }

    function testSetProtocolFeeAddress() public {
        vm.prank(platformOwner);
        platform.setProtocolFeeAddress(platformOwner);
    }

    function testSetPresaleFactoryFail() public {
        PresaleFactory factory = new PresaleFactory();

        vm.expectRevert();
        platform.setPresaleFactory(factory);

        vm.prank(platformOwner);
        vm.expectRevert(PresalePlatform.InvalidPresaleFactory.selector);
        platform.setPresaleFactory(PresaleFactory(address(0)));
    }

    function testSetPresaleFactory() public {
        PresaleFactory factory = new PresaleFactory();

        vm.prank(platformOwner);
        platform.setPresaleFactory(factory);
    }

    function testCreatePresale() public {
        PresaleMetadata memory presaleMetadata = PresaleMetadata("Presale Token", "PST", "", "", "");

        vm.prank(user);
        Presale presale = platform.createPresale(user, presaleMetadata, 1_000, 1e18, uint64(block.timestamp), 100);

        assertEq(uint256(platform.presaleStatus(presale)), uint256(PresalePlatform.PresaleStatus.Started));
    }

    function testUpdatePresale() public {
        PresaleMetadata memory presaleMetadata = PresaleMetadata("Presale Token", "PST", "", "", "");

        vm.prank(user);
        Presale presale = platform.createPresale(user, presaleMetadata, 1_000, 1e18, uint64(block.timestamp), 100);

        platform.updatePresale(presale);
        assertEq(uint256(platform.presaleStatus(presale)), uint256(PresalePlatform.PresaleStatus.Started));

        vm.warp(101);
        platform.updatePresale(presale);
        assertEq(uint256(platform.presaleStatus(presale)), uint256(PresalePlatform.PresaleStatus.Liquidity));

        vm.warp(101 + 14 days);
        platform.updatePresale(presale);
        assertEq(uint256(platform.presaleStatus(presale)), uint256(PresalePlatform.PresaleStatus.Ended));
    }
}

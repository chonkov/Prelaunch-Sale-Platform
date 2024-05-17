// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {PresaleFactory} from "../src/PresaleFactory.sol";
import {PresaleMetadata} from "../src/Presale.sol";

contract PresaleFactoryTest is Test {
    PresaleFactory factory;
    address user;
    PresaleMetadata metadata;

    function setUp() public {
        factory = new PresaleFactory();
        user = address(123);
        metadata = PresaleMetadata("Presale Token", "PST", "", "", "");
    }

    function testFailCreatePresale() public {
        vm.prank(user);
        factory.createPresale(user, metadata, 1_000, 1e18, uint64(block.timestamp), 5 days);
    }

    function testCreatePresale() public {
        factory.createPresale(user, metadata, 1_000, 1e18, uint64(block.timestamp), 5 days);
    }
}

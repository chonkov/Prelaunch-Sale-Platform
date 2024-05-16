// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20Metadata, IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IWETH is IERC20Metadata {
    function deposit() external payable;
}

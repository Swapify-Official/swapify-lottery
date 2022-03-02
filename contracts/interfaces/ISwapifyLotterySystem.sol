// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

interface ISwapifyLotterySystem {
    function mintTickets(address user, uint amount) external;
}
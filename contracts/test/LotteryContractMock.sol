// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import '../SwapifyLotterySystem.sol';

contract LotteryContractMock is SwapifyLotterySystem {

    constructor(address _rewardsTokenAddress) SwapifyLotterySystem(_rewardsTokenAddress) {}

    function mockDrawWinningNumber(uint8[] memory winningTickets) external {
        require(winningTickets.length == 4, 'Winning Ticket Positions must equal to 4');
        roundHistory[currentRound].winningNumbers.position1 = winningTickets[0];
        roundHistory[currentRound].winningNumbers.position2 = winningTickets[1];
        roundHistory[currentRound].winningNumbers.position3 = winningTickets[2];
        roundHistory[currentRound].winningNumbers.position4 = winningTickets[3];

        (roundHistory[currentRound].matchAll,
            roundHistory[currentRound].match3,
            roundHistory[currentRound].match2,
            roundHistory[currentRound].match1) = findWinningMatches(roundHistory[currentRound].tickets, currentRound);
            
        if(roundHistory[currentRound].match1 == 0 && roundHistory[currentRound].match2 == 0 && 
                    roundHistory[currentRound].match3 == 0 && roundHistory[currentRound].matchAll == 0) {
            roundHistory[currentRound].noMatch = true;
        }
        currentRound++;
        roundHistory[currentRound].round = currentRound;
        roundHistory[currentRound].reward = calculateCarryForwardRewards(currentRound - 1);
        roundHistory[currentRound].rewardRatio.matchAll = roundHistory[currentRound - 1].rewardRatio.matchAll;
        roundHistory[currentRound].rewardRatio.match3 = roundHistory[currentRound - 1].rewardRatio.match3;
        roundHistory[currentRound].rewardRatio.match2 = roundHistory[currentRound - 1].rewardRatio.match2;
        roundHistory[currentRound].rewardRatio.match1 = roundHistory[currentRound - 1].rewardRatio.match1;
    }

    function mockSubmitTicket(address user, uint8[] memory ticketPositions) external {
        require(ticketPositions.length % 4 == 0, 'Ticket Positions divided by 4');
        userRoundData[currentRound][user].round = currentRound;
        userRoundData[currentRound][user].user = user;
        uint count = ticketPositions.length / 4;
        for(uint i=0; i < ticketPositions.length; ) {
            Ticket memory ticket;
            ticket.position1 = ticketPositions[i++];
            ticket.position2 = ticketPositions[i++];
            ticket.position3 = ticketPositions[i++];
            ticket.position4 = ticketPositions[i++];

            userRoundData[currentRound][user].tickets.push(ticket);
            roundHistory[currentRound].tickets.push(ticket);
        }
        _burn(user, count);
    }
}
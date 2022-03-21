// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;
import './Permissible.sol';
import './SwapifyLotteryTicketERC20.sol';
import './libraries/SafeMath.sol';
import './libraries/Decimal.sol';

contract SwapifyLotterySystem is SwapifyLotteryTicketERC20, Permissible {
    using SafeMath  for uint;
    using Decimal for uint;

    struct Ticket{
        uint8 position1;
        uint8 position2;
        uint8 position3;
        uint8 position4;
    }
    struct RewardRatio {
        uint8 matchAll;
        uint8 match3;
        uint8 match2;
        uint8 match1;
    }
    struct UserData {
        uint round;
        address user;
        Ticket[] tickets;
        uint8[] boughtTickets;
        bool claimed;
        uint reward;
    }
    struct RoundData {
        uint round;
        Ticket winningNumbers;
        uint reward;
        Ticket[] tickets;
        RewardRatio rewardRatio;
        uint8 match1;
        uint8 match2;
        uint8 match3;
        uint8 matchAll;
        bool noMatch;
    }
    address public rewardsToken;

    uint8 public rewardRatio = 4;
    uint public currentRound;
    mapping(uint => RoundData) internal roundHistory;
    mapping(uint => mapping(address=> UserData)) internal userRoundData;
    
    uint internal nonce;

    constructor(address _rewardsTokenAddress) {
        rewardsToken = _rewardsTokenAddress;
        currentRound = 1;
        nonce = 7638264823492;
        roundHistory[currentRound].rewardRatio.matchAll = 50;
        roundHistory[currentRound].rewardRatio.match3 = 30;
        roundHistory[currentRound].rewardRatio.match2 = 15;
        roundHistory[currentRound].rewardRatio.match1 = 5;
    }
    /**
     * @dev show the current round reward.  Return uint. 
     */
    function currentReward() external view returns(uint) {
        return roundHistory[currentRound].reward;
    }
    /**
     * @dev shows array of tickets that are in current round.
     */
    function ticketsInCurrentRound() external view returns(Ticket[] memory) {
        return roundHistory[currentRound].tickets;
    }
    /**
     * @dev This function shows round data by round number
     */
    function getRoundHistory(uint round) external view returns(RoundData memory) {
        return roundHistory[round];
    }
    /**
     * @dev This function calculates rewards & show userdata
     */
    function getUserRoundData(address user, uint round) external view returns(UserData memory) {
        uint totalRewards;
        if(round < currentRound) {
            uint8 matchAll; 
            uint8 match3; 
            uint8 match2; 
            uint8 match1;
            
            (matchAll, match3, match2, match1) = findWinningMatches(userRoundData[round][user].tickets, round);
            totalRewards = calculateTotalRewardsToBeClaimed(matchAll, match3, match2, match1, round);
        }
        UserData memory userData = UserData({
            round: userRoundData[round][user].round,
            user: userRoundData[round][user].user,
            tickets: new Ticket[](0),
            boughtTickets: new uint8[](userRoundData[round][user].tickets.length * 4),
            claimed: userRoundData[round][user].claimed,
            reward: totalRewards
        });
        for(uint8 i=0; i < userRoundData[round][user].tickets.length; i++) {
            userData.boughtTickets[i * 4 + 0] = userRoundData[round][user].tickets[i].position1;
            userData.boughtTickets[i * 4 + 1] = userRoundData[round][user].tickets[i].position2;
            userData.boughtTickets[i * 4 + 2] = userRoundData[round][user].tickets[i].position3;
            userData.boughtTickets[i * 4 + 3] = userRoundData[round][user].tickets[i].position4;
        }
        return userData;
    }
    /**
     * @dev mints SwapifyTICKET and sends it to the specified address.  
     * This will be used in the DEX contract whenever trades get fulfilled.
     */
    function mintTickets(address user, uint swapifyLotteryTicketAmount) external onlyPermissible {
        require(user != address(0), 'SwapifyLotterySystem: ZERO_ADDRESS');
        require(swapifyLotteryTicketAmount > 0, 'SwapifyLotterySystem: ZERO_AMOUNT');
        _mint(user, swapifyLotteryTicketAmount);
    }
    /**
     * @dev This function mints SwapifyTICKET and sends it to the specified address.
     * User then has to pay a cost in Swapify, to purchase the ticket.  
     * The Reward for the current round will increment by the amount of Swapify’s that were sent to the contract.
     * rewardsAmount is being ERC20 token that accepts 18 decimal points so value need to be sent as value * (10 ** 18)
     * Swapify Ticket does not support any decimals so based on ratio set it accepts integral value only.
     */

     /*
    function buyTickets(address user, uint rewardsAmount) external {
        require(user != address(0), 'SwapifyLotterySystem: ZERO_ADDRESS');
        require(rewardsAmount > 0, 'SwapifyLotterySystem: Rewards ZERO_AMOUNT');
        uint swapifyTicketAmount = (rewardsAmount / (10 ** IERC20(rewardsToken).decimals())) / rewardRatio;
        require(swapifyTicketAmount > 0, 'SwapifyLotterySystem: Ticket ZERO_AMOUNT');
        require(IERC20(rewardsToken).transferFrom(user, address(this), rewardsAmount), 
                                    'SwapifyLotterySystem: User then has to pay a cost in Swapify, to purchase the ticket');
        _mint(user, swapifyTicketAmount);
        roundHistory[currentRound].reward = roundHistory[currentRound].reward.decimalAddition(rewardsAmount);
    }

    */

    /**
     * @dev user will submit the amount of tickets (SWAPATICKETS) and they must have sufficient amount of tickets in their wallet. 
     * This will then create an entry with 4 random numbers between 0 - 9. 
     * Each ticket user submits grants them one entry with 4 different and random numbers between 0 - 9.
     * User can only submit the amount of tickets that is equivalent to the amount of SWAPATICKETS they have in their wallet.  
     * When user submits ticket(s), SWAPATICKETS get burnt in the process.
     */
    function submitTicket(address user, uint amount) external {
        require(amount > 0, 'SwapifyLotterySystem: Amount is required to more than 0');
        userRoundData[currentRound][user].round = currentRound;
        userRoundData[currentRound][user].user = user;
        for(uint i=0; i < amount; i++) {
            Ticket memory ticket;
            ticket.position1 = generateRandomNumber();
            ticket.position2 = generateRandomNumber();
            ticket.position3 = generateRandomNumber();
            ticket.position4 = generateRandomNumber();

            userRoundData[currentRound][user].tickets.push(ticket);
            roundHistory[currentRound].tickets.push(ticket);
        }
        _burn(user, amount);
    }
    /**
     * @dev Admin can only use this function.  Adds SWAPIFY rewards to the current round.
     */
    function addReward(uint rewardAmount) external onlyOwner {
        require(IERC20(rewardsToken).transferFrom(owner(), address(this), rewardAmount), 
                        'SwapifyLotterySystem: Reward amount could not be deposited to the Lottery contract for the round');
        roundHistory[currentRound].reward = roundHistory[currentRound].reward.decimalAddition(rewardAmount);
    }
    /**
     * @dev Admin can change the reward ratio.
     * This ratio represents how many SWAPAFY required to buy 1 SWAPATICKET
     */
    function setRewardRatio(uint8 ratio) external onlyOwner {
        require(ratio > 0, 'SwapifyLotterySystem: ZERO_AMOUNT');
        rewardRatio = ratio;
    }
    function setRewardToken(address _rewardsTokenAddress) external onlyOwner {
        require(_rewardsTokenAddress != address(0), 'Address Empty');
        rewardsToken = _rewardsTokenAddress;
    }
    /**
     * @dev Admin draws the 4 winning numbers.  (Random numbers between 0-9).
     * Stores data on chain and starts a new round. Updates the mapping for rounds.
     * Only Admin can execute this function.
     */
    function drawWinningNumber() external onlyOwner {
        roundHistory[currentRound].winningNumbers.position1 = generateRandomNumber();
        roundHistory[currentRound].winningNumbers.position2 = generateRandomNumber();
        roundHistory[currentRound].winningNumbers.position3 = generateRandomNumber();
        roundHistory[currentRound].winningNumbers.position4 = generateRandomNumber();

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
    /**
     * @dev set nonce for randomize ticket generation.
     */
    function setNonce(uint _nonce) external onlyOwner {
        nonce = _nonce;
    }
    /**
     * @dev updates the reward allocation ratio for each pool.  Ratios must add up to 1.  
     * Example:  updateMatchPoolAllocation(0.5, 0.3, 0.15, 0.05)
     */
    function updateMatchPoolAllocation(uint8 matchAll, uint8 match3, uint8 match2, uint8 match1) external onlyOwner {
        require(matchAll + match3 + match2 + match1 == 100, 'Ratios must add up to 100%');
        roundHistory[currentRound].rewardRatio.matchAll = matchAll;
        roundHistory[currentRound].rewardRatio.match3 = match3;
        roundHistory[currentRound].rewardRatio.match2 = match2;
        roundHistory[currentRound].rewardRatio.match1 = match1;
    }
    /**
     * @dev claims rewards during the specified round if there are any to be claimed.
     */
    function claimRewards(address user, uint round) external {
        uint8 matchAll; 
        uint8 match3; 
        uint8 match2; 
        uint8 match1;
        
        (matchAll, match3, match2, match1) = findWinningMatches(userRoundData[round][user].tickets, round);
        uint totalRewards = calculateTotalRewardsToBeClaimed(matchAll, match3, match2, match1, round);
        userRoundData[round][user].reward = totalRewards;
        userRoundData[round][user].claimed = true;
        IERC20(rewardsToken).transfer(user, totalRewards);
    }
    /**
     * @dev Internal method. It finds number of different types of matches from list tickets in a specified round
     */
    function findWinningMatches(Ticket[] memory tickets, uint round) internal view returns 
                                                    (uint8 matchAll, uint8 match3, uint8 match2, uint8 match1) {
        for(uint i=0; i < tickets.length; i++) {
            if(tickets[i].position1 == roundHistory[round].winningNumbers.position1 &&
                    tickets[i].position2 == roundHistory[round].winningNumbers.position2 &&
                    tickets[i].position3 == roundHistory[round].winningNumbers.position3 &&
                    tickets[i].position4 == roundHistory[round].winningNumbers.position4) {
                matchAll++;
            } else if(tickets[i].position1 == roundHistory[round].winningNumbers.position1 &&
                    tickets[i].position2 == roundHistory[round].winningNumbers.position2 &&
                    tickets[i].position3 == roundHistory[round].winningNumbers.position3) {
                match3++;
            } else if(tickets[i].position1 == roundHistory[round].winningNumbers.position1 &&
                    tickets[i].position2 == roundHistory[round].winningNumbers.position2) {
                match2++;
            } else if(tickets[i].position1 == roundHistory[round].winningNumbers.position1) {
                match1++;
            }
        }
    }
    /**
     * @dev Internal function. It calculates carry forward not won rewards from previous round to next round.
     */
    function calculateCarryForwardRewards(uint round) internal view returns(uint) {
        if(roundHistory[round].noMatch) {
            return roundHistory[round].reward;
        }

        uint totalRewardToBeClaimed = calculateTotalRewardsToBeClaimed(roundHistory[round].matchAll, 
                                                                        roundHistory[round].match3,
                                                                        roundHistory[round].match2,
                                                                        roundHistory[round].match1, round);

        return roundHistory[round].reward.decimalSubtraction(totalRewardToBeClaimed);
    }
    /**
     * @dev Internal finction. It calculates total rewards that can be claimed by given number of matches for a specified round.
     */
    function calculateTotalRewardsToBeClaimed(uint8 matchAll, uint8 match3, uint8 match2, uint8 match1, uint round) internal view returns(uint) {
        uint matchAllTotalReward = roundHistory[round].reward.uintMultiply(roundHistory[round].rewardRatio.matchAll) / 100;
        uint match3TotalReward = roundHistory[round].reward.uintMultiply(roundHistory[round].rewardRatio.match3) / 100;
        uint match2TotalReward = roundHistory[round].reward.uintMultiply(roundHistory[round].rewardRatio.match2) / 100;
        uint match1TotalReward = roundHistory[round].reward.uintMultiply(roundHistory[round].rewardRatio.match1) / 100;

        uint totalRewards = 0;

        if(roundHistory[round].matchAll > 0 && matchAll > 0) {
            totalRewards += matchAllTotalReward.uintMultiply(matchAll) / roundHistory[round].matchAll;
        }
        if(roundHistory[round].match3 > 0 && match3 > 0) {
            totalRewards += match3TotalReward.uintMultiply(match3) / roundHistory[round].match3;
        }
        if(roundHistory[round].match2 > 0 && match2 > 0) {
            totalRewards += match2TotalReward.uintMultiply(match2) / roundHistory[round].match2;
        }
        if(roundHistory[round].match1 > 0 && match1 > 0) {
            totalRewards += match1TotalReward.uintMultiply(match1) / roundHistory[round].match1;
        }

        return totalRewards;
    }
    /**
     * @dev Internal function. It generates random number based on set nonce
     */
    function generateRandomNumber() internal returns (uint8){
        nonce += 3;
        return uint8(uint(keccak256(abi.encodePacked(blockhash(block.number), msg.sender, block.timestamp, nonce))) % 10);
    }
}
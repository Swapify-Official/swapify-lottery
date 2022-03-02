import chai, { expect } from 'chai'
import { Contract } from 'ethers'
import { AddressZero, Zero, MaxUint256 } from 'ethers/constants'
import { BigNumber, bigNumberify } from 'ethers/utils'
import { solidity, MockProvider, createFixtureLoader } from 'ethereum-waffle'

import { expandTo18Decimals, mineBlock, encodePrice } from './shared/utilities'
import { v2Fixture } from './shared/fixtures'


chai.use(solidity)

const overrides = {
    gasLimit: 9999999
}

describe('SwapifyLotterySystem', () => {
    const provider = new MockProvider({
        hardfork: 'istanbul',
        mnemonic: 'horn horn horn horn horn horn horn horn horn horn horn horn',
        gasLimit: 9999999
    })
    const [wallet, otherWallet] = provider.getWallets()
    const loadFixture = createFixtureLoader(provider, [wallet])

    let rewardsToken: Contract
    let Lottery: Contract
    let LotteryMock: Contract
    let rewardsTokenMock:Contract

    beforeEach(async function() {
        const fixture = await loadFixture(v2Fixture)
        Lottery = fixture.Lottery
        rewardsToken = fixture.rewardsToken
        LotteryMock = fixture.LotteryMock
        rewardsTokenMock = fixture.rewardsTokenMock
    })

    it('currentRound', async () => {
        expect(await Lottery.currentRound()).to.eq(1)
    })

    it('currentReward', async () => {
        expect(await Lottery.currentReward()).to.eq(0)
    })

    it('setRewardRatio', async () => {
        expect(await Lottery.rewardRatio()).to.eq(4)
        await expect(Lottery.setRewardRatio(0)).to.be.revertedWith('SwapifyLotterySystem: ZERO_AMOUNT')
        await Lottery.setRewardRatio(10)
        expect(await Lottery.rewardRatio()).to.eq(10)
    })

    it('getRoundHistory default Rewards ratios', async () => {
        const roundHistory = await Lottery.getRoundHistory(1)
        expect(roundHistory.rewardRatio.matchAll).to.eq(50)
        expect(roundHistory.rewardRatio.match3).to.eq(30)
        expect(roundHistory.rewardRatio.match2).to.eq(15)
        expect(roundHistory.rewardRatio.match1).to.eq(5)
    })

    it('mintTickets', async () => {
        await expect(Lottery.mintTickets(AddressZero, MaxUint256)).to.be.revertedWith('SwapifyLotterySystem: ZERO_ADDRESS')
        await expect(Lottery.mintTickets(wallet.address, 0)).to.be.revertedWith('SwapifyLotterySystem: ZERO_AMOUNT')
        await expect(Lottery.mintTickets(wallet.address, 10, overrides)).to.emit(Lottery, 'Transfer').withArgs(AddressZero, wallet.address, 10)
        expect(await Lottery.totalSupply()).to.eq(10)
        expect(await Lottery.balanceOf(wallet.address)).to.eq(10)
    })
    it('addReward ownership test', async () => {
        const rewardTokenAmount = expandTo18Decimals(2536)
        await Lottery.transferOwnership(otherWallet.address)
        await expect(Lottery.addReward(rewardTokenAmount)).to.be.revertedWith('Ownable: caller is not the owner')
    })
    it('addReward', async () => {
        const rewardTokenAmount = expandTo18Decimals(2536)
        await expect(Lottery.addReward(rewardTokenAmount)).to.be.revertedWith('SwapifyRewardsERC20: transfer amount exceeds allowance')
        await rewardsToken.mint(wallet.address, rewardTokenAmount)
        await rewardsToken.approve(Lottery.address, rewardTokenAmount)
        await Lottery.addReward(rewardTokenAmount)
        expect(await Lottery.currentReward()).to.eq(rewardTokenAmount)
        const roundHistory = await Lottery.getRoundHistory(1)
        expect(roundHistory.reward).to.eq(rewardTokenAmount)
    })
    it('buyTickets', async () => {
        await expect(Lottery.buyTickets(AddressZero, MaxUint256)).to.be.revertedWith('SwapifyLotterySystem: ZERO_ADDRESS')
        await expect(Lottery.buyTickets(wallet.address, 0)).to.be.revertedWith('SwapifyLotterySystem: Rewards ZERO_AMOUNT')
        const rewardTokenAmount = expandTo18Decimals(40)
        await rewardsToken.mint(wallet.address, rewardTokenAmount)
        await rewardsToken.approve(Lottery.address, rewardTokenAmount)
        await Lottery.buyTickets(wallet.address, rewardTokenAmount)
        expect(await Lottery.totalSupply()).to.eq(10)
        const roundHistory = await Lottery.getRoundHistory(1)
        expect(roundHistory.reward).to.eq(rewardTokenAmount)
    })
    it('submitTicket', async () => {
        await expect(Lottery.submitTicket(wallet.address, 0)).to.be.revertedWith('SwapifyLotterySystem: Amount is required to more than 0')
        await expect(Lottery.submitTicket(wallet.address, 10)).to.be.revertedWith('SwapifyLotteryTicketERC20: burn amount exceeds balance of the holder')
        const rewardTokenAmount = expandTo18Decimals(40)
        await rewardsToken.mint(wallet.address, rewardTokenAmount)
        await rewardsToken.approve(Lottery.address, rewardTokenAmount)
        await Lottery.buyTickets(wallet.address, rewardTokenAmount)
        expect(await Lottery.totalSupply()).to.eq(10)
        await Lottery.submitTicket(wallet.address, 10)
        expect(await Lottery.totalSupply()).to.eq(0)
        const tickets = await Lottery.ticketsInCurrentRound()
        expect(tickets.length).to.eq(10)
        const roundHistory = await Lottery.getRoundHistory(1)
        const roundTicketsCount = roundHistory.tickets.length
        expect(roundTicketsCount).to.eq(10)
        const userRoundData = await Lottery.getUserRoundData(wallet.address, 1)
        const userTicketsCount = userRoundData.boughtTickets.length
        expect(userTicketsCount).to.eq(10 * 4)
    })
    it('drawWinningNumber ownership test', async () => {
        const rewardTokenAmount = expandTo18Decimals(2536)
        await Lottery.transferOwnership(otherWallet.address)
        await expect(Lottery.drawWinningNumber()).to.be.revertedWith('Ownable: caller is not the owner')
    })
    it('drawWinningNumber', async () => {
        const rewardTokenAmount = expandTo18Decimals(2536)
        await rewardsToken.mint(wallet.address, rewardTokenAmount)
        await rewardsToken.approve(Lottery.address, rewardTokenAmount)
        await Lottery.addReward(rewardTokenAmount)
        expect(await Lottery.currentReward()).to.eq(rewardTokenAmount)

        const rewardBuyTokenAmount = expandTo18Decimals(40)
        await rewardsToken.mint(wallet.address, rewardBuyTokenAmount)
        await rewardsToken.approve(Lottery.address, rewardBuyTokenAmount)
        await Lottery.buyTickets(wallet.address, rewardBuyTokenAmount)
        expect(await Lottery.totalSupply()).to.eq(10)
        await Lottery.submitTicket(wallet.address, 10)
        
        expect(await Lottery.currentRound()).to.eq(1)
        await Lottery.drawWinningNumber(overrides)
        expect(await Lottery.currentRound()).to.eq(2)

        const prevRoundHistory = await Lottery.getRoundHistory(1)
        const matchNotFound = prevRoundHistory.noMatch
        const rewardAmount = prevRoundHistory.reward
        expect(rewardAmount).to.eq(expandTo18Decimals(2536 + 40))
        expect(prevRoundHistory.winningNumbers.position1).to.greaterThanOrEqual(0)
        expect(prevRoundHistory.winningNumbers.position2).to.greaterThanOrEqual(0)
        expect(prevRoundHistory.winningNumbers.position3).to.greaterThanOrEqual(0)
        expect(prevRoundHistory.winningNumbers.position4).to.greaterThanOrEqual(0)

        const roundHistory = await Lottery.getRoundHistory(2)
        if(matchNotFound) expect(roundHistory.reward).to.eq(rewardAmount)
        expect(roundHistory.rewardRatio.matchAll).to.eq(50)
        expect(roundHistory.rewardRatio.match3).to.eq(30)
        expect(roundHistory.rewardRatio.match2).to.eq(15)
        expect(roundHistory.rewardRatio.match1).to.eq(5)
        expect(roundHistory.winningNumbers.position1).to.eq(0)
        expect(roundHistory.winningNumbers.position2).to.eq(0)
        expect(roundHistory.winningNumbers.position3).to.eq(0)
        expect(roundHistory.winningNumbers.position4).to.eq(0)
    })
    it('updateMatchPoolAllocation', async () => {
        await expect(Lottery.updateMatchPoolAllocation(50,30,20,10)).to.be.revertedWith('Ratios must add up to 100%')
        await Lottery.updateMatchPoolAllocation(40,30,20,10)
        const currentRound = await Lottery.currentRound()
        const currentRoundHistory = await Lottery.getRoundHistory(currentRound)
        expect(currentRoundHistory.rewardRatio.matchAll).to.eq(40)
        expect(currentRoundHistory.rewardRatio.match3).to.eq(30)
        expect(currentRoundHistory.rewardRatio.match2).to.eq(20)
        expect(currentRoundHistory.rewardRatio.match1).to.eq(10)
    })
    it('claimRewards', async () => {
        const rewardTokenAmount = expandTo18Decimals(2536)
        await rewardsTokenMock.mint(wallet.address, rewardTokenAmount)
        await rewardsTokenMock.approve(wallet.address, LotteryMock.address, rewardTokenAmount)
        await LotteryMock.addReward(rewardTokenAmount)
        expect(await LotteryMock.currentReward()).to.eq(rewardTokenAmount)

        const rewardBuyTokenAmount = expandTo18Decimals(40)
        await rewardsTokenMock.mint(wallet.address, rewardBuyTokenAmount)
        await rewardsTokenMock.approve(wallet.address, LotteryMock.address, rewardBuyTokenAmount)
        await LotteryMock.buyTickets(wallet.address, rewardBuyTokenAmount)
        expect(await LotteryMock.totalSupply()).to.eq(10)
        let boughtTickets = [5,2,7,1,5,2,7,7,5,2,3,4,5,3,3,6]
        await LotteryMock.mockSubmitTicket(wallet.address, boughtTickets, overrides)
        const tickets = await LotteryMock.ticketsInCurrentRound()
        expect(tickets.length).to.eq(4)
        
        expect(await LotteryMock.currentRound()).to.eq(1)
        let winningTickets = [5,2,7,1]
        await LotteryMock.mockDrawWinningNumber(winningTickets, overrides)
        expect(await LotteryMock.currentRound()).to.eq(2)

        const prevRoundHistory = await LotteryMock.getRoundHistory(1)
        const matchNotFound = prevRoundHistory.noMatch
        expect(matchNotFound).to.eq(false)
        const rewardAmount = prevRoundHistory.reward
        expect(rewardAmount).to.eq(expandTo18Decimals(2536 + 40))
        expect(prevRoundHistory.winningNumbers.position1).to.eq(5)
        expect(prevRoundHistory.winningNumbers.position2).to.eq(2)
        expect(prevRoundHistory.winningNumbers.position3).to.eq(7)
        expect(prevRoundHistory.winningNumbers.position4).to.eq(1)
        expect(prevRoundHistory.noMatch).to.eq(false)
        expect(prevRoundHistory.matchAll).to.eq(1)
        expect(prevRoundHistory.match3).to.eq(1)
        expect(prevRoundHistory.match2).to.eq(1)
        expect(prevRoundHistory.match1).to.eq(1)

        const roundHistory = await Lottery.getRoundHistory(2)
        expect(roundHistory.reward).to.eq(0)

        let userRoundData = await LotteryMock.getUserRoundData(wallet.address, 1)
        let userRewardClaimed = userRoundData.claimed
        expect(userRewardClaimed).to.eq(false)
        let userReward = userRoundData.reward
        expect(userReward).to.eq(expandTo18Decimals(2536 + 40))

        await LotteryMock.claimRewards(wallet.address, 1)
        userRoundData = await LotteryMock.getUserRoundData(wallet.address, 1)
        userRewardClaimed = userRoundData.claimed
        expect(userRewardClaimed).to.eq(true)
        userReward = userRoundData.reward
        expect(userReward).to.eq(expandTo18Decimals(2536 + 40))
        expect(await rewardsTokenMock.balanceOf(wallet.address)).to.eq(expandTo18Decimals(2536 + 40))
    })

    it('claimRewards multiple user wins', async () => {
        const rewardTokenAmount = expandTo18Decimals(2536)
        await rewardsTokenMock.mint(wallet.address, rewardTokenAmount)
        await rewardsTokenMock.approve(wallet.address, LotteryMock.address, rewardTokenAmount)
        await LotteryMock.addReward(rewardTokenAmount)
        expect(await LotteryMock.currentReward()).to.eq(rewardTokenAmount)

        const rewardUser1BuyTokenAmount = expandTo18Decimals(16)
        await rewardsTokenMock.mint(wallet.address, rewardUser1BuyTokenAmount)
        await rewardsTokenMock.approve(wallet.address, LotteryMock.address, rewardUser1BuyTokenAmount)
        await LotteryMock.buyTickets(wallet.address, rewardUser1BuyTokenAmount)
        expect(await LotteryMock.totalSupply()).to.eq(4)
        let user1BoughtTickets = [5,2,7,1,5,2,3,7,5,2,9,4,5,3,3,6] // 1 MatchAll of 2, 2 Match2 of 3, 1 Match1 of 2
        await LotteryMock.mockSubmitTicket(wallet.address, user1BoughtTickets, overrides)
        let tickets = await LotteryMock.ticketsInCurrentRound()
        expect(tickets.length).to.eq(4)

        const rewardUser2BuyTokenAmount = expandTo18Decimals(16)
        await rewardsTokenMock.mint(otherWallet.address, rewardUser2BuyTokenAmount)
        await rewardsTokenMock.approve(otherWallet.address, LotteryMock.address, rewardUser2BuyTokenAmount)
        await LotteryMock.buyTickets(otherWallet.address, rewardUser2BuyTokenAmount)
        expect(await LotteryMock.totalSupply()).to.eq(4)
        let user2BoughtTickets = [5,2,7,1,5,8,9,2,4,1,3,8,5,2,3,7] // 1 MatchAll of 2, 1 Match2 of 3, 1 Match1 of 2
        await LotteryMock.mockSubmitTicket(otherWallet.address, user2BoughtTickets, overrides)
        tickets = await LotteryMock.ticketsInCurrentRound()
        expect(tickets.length).to.eq(8)

        expect(await LotteryMock.currentRound()).to.eq(1)
        let winningTickets = [5,2,3,7]
        await LotteryMock.mockDrawWinningNumber(winningTickets, overrides)
        expect(await LotteryMock.currentRound()).to.eq(2)

        const prevRoundHistory = await LotteryMock.getRoundHistory(1)
        const matchNotFound = prevRoundHistory.noMatch
        expect(matchNotFound).to.eq(false)
        const rewardAmount = prevRoundHistory.reward
        expect(rewardAmount).to.eq(expandTo18Decimals(2536 + 16 + 16))
        expect(prevRoundHistory.winningNumbers.position1).to.eq(5)
        expect(prevRoundHistory.winningNumbers.position2).to.eq(2)
        expect(prevRoundHistory.winningNumbers.position3).to.eq(3)
        expect(prevRoundHistory.winningNumbers.position4).to.eq(7)
        expect(prevRoundHistory.noMatch).to.eq(false)
        expect(prevRoundHistory.matchAll).to.eq(2)
        expect(prevRoundHistory.match3).to.eq(0)
        expect(prevRoundHistory.match2).to.eq(3)
        expect(prevRoundHistory.match1).to.eq(2)

        const roundHistory = await LotteryMock.getRoundHistory(2)
        expect(roundHistory.reward).to.eq(bigNumberify('770400000000000000000'))

        let user1RoundData = await LotteryMock.getUserRoundData(wallet.address, 1)
        let user1RewardClaimed = user1RoundData.claimed
        expect(user1RewardClaimed).to.eq(false)
        let user1Reward = user1RoundData.reward
        expect(user1Reward).to.eq(bigNumberify('963000000000000000000'))

        await LotteryMock.claimRewards(wallet.address, 1)
        user1RoundData = await LotteryMock.getUserRoundData(wallet.address, 1)
        user1RewardClaimed = user1RoundData.claimed
        expect(user1RewardClaimed).to.eq(true)
        user1Reward = user1RoundData.reward
        expect(user1Reward).to.eq(bigNumberify('963000000000000000000'))
        expect(await rewardsTokenMock.balanceOf(wallet.address)).to.eq(bigNumberify('963000000000000000000'))
        
        let user2RoundData = await LotteryMock.getUserRoundData(otherWallet.address, 1)
        let user2RewardClaimed = user2RoundData.claimed
        expect(user2RewardClaimed).to.eq(false)
        let user2Reward = user2RoundData.reward
        expect(user2Reward).to.eq(bigNumberify('834600000000000000000'))
        
        await LotteryMock.claimRewards(otherWallet.address, 1)
        user2RoundData = await LotteryMock.getUserRoundData(otherWallet.address, 1)
        user2RewardClaimed = user2RoundData.claimed
        expect(user2RewardClaimed).to.eq(true)
        user2Reward = user2RoundData.reward
        expect(user2Reward).to.eq(bigNumberify('834600000000000000000'))
        expect(await rewardsTokenMock.balanceOf(otherWallet.address)).to.eq(bigNumberify('834600000000000000000'))
    })
})
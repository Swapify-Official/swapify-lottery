import { Wallet, Contract } from 'ethers'
import { Web3Provider } from 'ethers/providers'
import { deployContract } from 'ethereum-waffle'

import SwapifyLotterySystem from '../../build/SwapifyLotterySystem.json'
import SwapifyRewardsERC20 from '../../build/SwapifyRewardsERC20.json'
import LotteryContractMock from '../../build/LotteryContractMock.json'
import SwapifyRewardsERC20Mock from '../../build/SwapifyRewardsERC20Mock.json'

const overrides = {
    gasLimit: 9999999
}

interface V2Fixture {
    rewardsToken: Contract
    Lottery: Contract
    LotteryMock: Contract
    rewardsTokenMock: Contract
}

export async function v2Fixture(provider: Web3Provider, [wallet]: Wallet[]): Promise<V2Fixture> {
    const rewardsToken = await deployContract(wallet, SwapifyRewardsERC20)
    const Lottery = await deployContract(wallet, SwapifyLotterySystem, [rewardsToken.address], overrides)
    const rewardsTokenMock = await deployContract(wallet, SwapifyRewardsERC20Mock)
    const LotteryMock = await deployContract(wallet, LotteryContractMock, [rewardsTokenMock.address], overrides)

    return {
        rewardsToken,
        Lottery,
        LotteryMock,
        rewardsTokenMock
    }
}
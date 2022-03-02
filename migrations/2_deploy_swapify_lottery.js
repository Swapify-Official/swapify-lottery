const SwapifyLotterySystem = artifacts.require("SwapifyLotterySystem.sol");
const SwapifyRewardsERC20 = artifacts.require("SwapifyRewardsERC20.sol");

module.exports = async function(deployer) {
    const OWNER_ID = '0x8871eE0752C9099698e78a2A065d42D295bcf23E';

    await deployer.deploy(SwapifyRewardsERC20);
    let rewardsTokenAddress = await SwapifyRewardsERC20.deployed();
    const lottery = await deployer.deploy(SwapifyLotterySystem, rewardsTokenAddress.address);
    await lottery.transferOwnership(OWNER_ID);
};

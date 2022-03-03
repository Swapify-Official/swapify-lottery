const SwapifyLotterySystem = artifacts.require("SwapifyLotterySystem.sol");
const SwapifyRewardsERC20 = artifacts.require("SwapifyRewardsERC20.sol");

module.exports = async function(deployer, address) {
    const OWNER_ID = '0xCDB1c8BD7f31f6EfaeDe6B616d669561292D9Ea5';

    await deployer.deploy(SwapifyRewardsERC20);
    let rewardsTokenAddress = await SwapifyRewardsERC20.deployed();
    const lottery = await deployer.deploy(SwapifyLotterySystem, rewardsTokenAddress.address);
    await lottery.transferOwnership(OWNER_ID);
};

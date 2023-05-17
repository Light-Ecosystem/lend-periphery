import { RewardsController } from './../../types/RewardsController.d';
import {
  waitForTx,
  MAX_UINT_AMOUNT,
  ZERO_ADDRESS,
  deployReservesSetupHelper,
} from 'lend-deploy';
import { expect } from 'chai';
import { makeSuite } from '../helpers/make-suite';
import { RANDOM_ADDRESSES } from '../helpers/constants';
import hre from 'hardhat';

makeSuite('RewardsController misc tests', (testEnv) => {
  it('Deployment should pass', async () => {
    const peiEmissionManager = RANDOM_ADDRESSES[1];
    const { deployer } = await hre.getNamedAccounts();

    if (process.env.COVERAGE === 'true') {
      console.log('Skip due coverage loss of data');
      return;
    }
    const artifact = await hre.deployments.deploy('RewardsController', {
      from: deployer,
      args: [peiEmissionManager],
    });
    const rewardsController = (await hre.ethers.getContractAt(
      artifact.abi,
      artifact.address
    )) as RewardsController;
    await expect((await rewardsController.EMISSION_MANAGER()).toString()).to.be.equal(
      peiEmissionManager
    );
    await expect((await rewardsController.getEmissionManager()).toString()).to.be.equal(
      peiEmissionManager
    );
  });

  it('Should claimRewards revert if performTransfer strategy call returns false', async () => {
    const {
      hDaiMockV2,
      users,
      rewardsController,
      distributionEnd,
      rewardToken: { address: reward },
      deployer,
    } = testEnv;
    const [userWithRewards] = users;

    const mockStrategy = await hre.deployments.deploy('MockBadTransferStrategy', {
      from: deployer.address,
      args: [rewardsController.address, deployer.address],
    });

    await waitForTx(
      await rewardsController.configureAssets([
        {
          asset: hDaiMockV2.address,
          reward,
          rewardOracle: testEnv.hopePriceAggregator,
          emissionPerSecond: '2000',
          distributionEnd,
          totalSupply: '0',
          transferStrategy: mockStrategy.address,
        },
      ])
    );
    await waitForTx(await hDaiMockV2.setUserBalanceAndSupply('300000', '30000'));

    await expect(
      rewardsController.connect(userWithRewards.signer).claimAllRewardsToSelf([hDaiMockV2.address])
    ).to.be.revertedWith('TRANSFER_ERROR');
  });
});

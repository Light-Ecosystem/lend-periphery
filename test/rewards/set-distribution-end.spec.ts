import { makeSuite, TestEnv } from '../helpers/make-suite';
import { ZERO_ADDRESS } from 'lend-deploy';

const { expect } = require('chai');

makeSuite('HopeLendIncentivesControllerV2 setDistributionEnd', (testEnv: TestEnv) => {
  it('Revert at setDistributionEnd if not emissionManager', async () => {
    const {
      rewardsController,
      users: [user1],
    } = testEnv;

    await expect(
      rewardsController.connect(user1.signer).setDistributionEnd(ZERO_ADDRESS, ZERO_ADDRESS, 0)
    ).to.be.revertedWith('ONLY_EMISSION_MANAGER');
  });
});

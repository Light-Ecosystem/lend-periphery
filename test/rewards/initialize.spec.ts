import { makeSuite, TestEnv } from '../helpers/make-suite';
import { ZERO_ADDRESS } from 'lend-deploy';

const { expect } = require('chai');

makeSuite('HopeLendIncentivesControllerV2 initialize', (testEnv: TestEnv) => {
  it('Tries to call initialize second time, should be reverted', async () => {
    const { rewardsController } = testEnv;
    await expect(rewardsController.initialize(ZERO_ADDRESS)).to.be.reverted;
  });
});

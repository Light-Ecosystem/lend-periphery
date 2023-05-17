import { expect } from 'chai';
import {
  ZERO_ADDRESS,
  RewardsController__factory,
  evmSnapshot,
  evmRevert,
  ONE_ADDRESS,
} from 'lend-deploy';
import { makeSuite, TestEnv } from '../helpers/make-suite';
import { deployMockContract } from '@ethereum-waffle/mock-contract';

makeSuite('EmissionManager', (testEnv: TestEnv) => {
  let mockRewardsController;
  let snapId;
  before(async () => {
    const { deployer, emissionManager } = testEnv;
    mockRewardsController = await deployMockContract(
      deployer.signer,
      RewardsController__factory.abi
    );
    console.log('Mock', mockRewardsController.address);
    await emissionManager.setRewardsController(mockRewardsController.address);
  });

  beforeEach(async () => {
    snapId = await evmSnapshot();
  });

  afterEach(async () => {
    await evmRevert(snapId);
  });

  it('Owner sets a new rewards controller', async () => {
    const { emissionManager } = testEnv;

    expect(await emissionManager.getRewardsController()).to.be.eq(mockRewardsController.address);
    expect(await emissionManager.setRewardsController(ZERO_ADDRESS));
    expect(await emissionManager.getRewardsController()).to.be.eq(ZERO_ADDRESS);
  });

  it('Non-owner user tries to set a new rewards controller (revert expected)', async () => {
    const { emissionManager, users } = testEnv;

    await expect(
      emissionManager.connect(users[0].signer).setRewardsController(ZERO_ADDRESS)
    ).to.be.revertedWith('Ownable: caller is not the owner');
  });

  it('Non-owner user tries to set a new emission admin (revert expected)', async () => {
    const { emissionManager, rewardToken, users } = testEnv;
    expect(await emissionManager.getEmissionAdmin(rewardToken.address)).to.be.eq(ZERO_ADDRESS);
    await expect(
      emissionManager
        .connect(users[0].signer)
        .setEmissionAdmin(rewardToken.address, users[1].address)
    ).to.be.revertedWith('Ownable: caller is not the owner');
    expect(await emissionManager.getEmissionAdmin(rewardToken.address)).to.be.eq(ZERO_ADDRESS);
  });

  it('Owner sets a new emission admin', async () => {
    const { emissionManager, rewardToken, users } = testEnv;

    expect(await emissionManager.getEmissionAdmin(rewardToken.address)).to.be.eq(ZERO_ADDRESS);
    expect(await emissionManager.setEmissionAdmin(rewardToken.address, users[1].address))
      .to.emit(emissionManager, 'EmissionAdminUpdated')
      .withArgs(rewardToken.address, ZERO_ADDRESS, users[1].address);
    expect(await emissionManager.getEmissionAdmin(rewardToken.address)).to.be.eq(users[1].address);
  });

  it('Non-owner user tries to set an authorized claimer (revert expected)', async () => {
    const { emissionManager, rewardToken, users } = testEnv;

    await expect(
      emissionManager.connect(users[0].signer).setClaimer(users[0].address, users[1].address)
    ).to.be.revertedWith('Ownable: caller is not the owner');
  });

  it('Owner sets an authorized claimer', async () => {
    const { emissionManager, rewardToken, users } = testEnv;
    await mockRewardsController.mock.setClaimer.returns();
    expect(await emissionManager.setClaimer(users[0].address, users[1].address));
  });

  it('Test the accessibility of onlyEmissionAdmin modified functions', async () => {
    const { emissionManager, rewardToken, users } = testEnv;
    const randomAddress = ONE_ADDRESS;
    const randomNumber = 20232312;

    const calls = [
      { fn: 'setTransferStrategy', args: [rewardToken.address, randomAddress] },
      { fn: 'setRewardOracle', args: [rewardToken.address, randomAddress] },
      { fn: 'setDistributionEnd', args: [randomAddress, rewardToken.address, randomNumber] },
    ];

    // Revert expected
    for (const call of calls) {
      await expect(
        emissionManager.connect(users[1].signer)[call.fn](...call.args)
      ).to.be.revertedWith('ONLY_EMISSION_ADMIN');
    }

    // Add User1 as emission admin
    expect(await emissionManager.setEmissionAdmin(rewardToken.address, users[1].address));

    for (const call of calls) {
      await mockRewardsController.mock[call.fn].returns();
      expect(await emissionManager.connect(users[1].signer)[call.fn](...call.args));
    }
  });
});

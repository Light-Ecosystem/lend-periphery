import { PullRewardsTransferStrategy } from './../../types/PullRewardsTransferStrategy';
import { HTokenMock } from './../../types/HTokenMock.d';
import { RewardsController } from './../../types/RewardsController';
import hre from 'hardhat';
import { Signer } from 'ethers';
import bluebird from 'bluebird';
import { usingTenderly } from '../../helpers/tenderly-utils';
import chai from 'chai';
import bignumberChai from 'chai-bignumber';
import {
  getPool,
  getPoolConfiguratorProxy,
  getPoolAddressesProvider,
  getPoolAddressesProviderRegistry,
  getHopeLendProtocolDataProvider,
  getHToken,
  getVariableDebtToken,
  getStableDebtToken,
  getMintableERC20,
  getWETHMocked,
  evmSnapshot,
  evmRevert,
  HopeLendProtocolDataProvider,
  HToken,
  MintableERC20,
  Pool,
  PoolAddressesProvider,
  PoolAddressesProviderRegistry,
  PoolConfigurator,
  StableDebtToken,
  VariableDebtToken,
  WETH9Mocked,
  HopeOracle,
  getWrappedTokenGateway,
  WrappedTokenGateway,
  tEthereumAddress,
  getEthersSigners,
  getHopeOracle,
  getIncentivesV2,
  getBlockTimestamp,
  TESTNET_REWARD_TOKEN_PREFIX,
  getSubTokensByPrefix,
  getPullRewardsStrategy,
  waitForTx,
  MAX_UINT_AMOUNT,
  TESTNET_PRICE_AGGR_PREFIX,
  deployMintableERC20,
  impersonateAddress,
  getEmissionManager,
} from 'lend-deploy';
import { deployHTokenMock } from '../rewards/helpers/deploy';
import { parseEther } from 'ethers/lib/utils';
import { EmissionManager, EmissionManager__factory } from '../../types';

chai.use(bignumberChai());

export interface SignerWithAddress {
  signer: Signer;
  address: tEthereumAddress;
}

export interface TestEnv {
  deployer: SignerWithAddress;
  users: SignerWithAddress[];
  poolAdmin: SignerWithAddress;
  emergencyAdmin: SignerWithAddress;
  riskAdmin: SignerWithAddress;
  pool: Pool;
  configurator: PoolConfigurator;
  oracle: HopeOracle;
  helpersContract: HopeLendProtocolDataProvider;
  weth: WETH9Mocked;
  hWETH: HToken;
  dai: MintableERC20;
  hDai: HToken;
  variableDebtDai: VariableDebtToken;
  stableDebtDai: StableDebtToken;
  hUsdc: HToken;
  usdc: MintableERC20;
  hope: MintableERC20;
  addressesProvider: PoolAddressesProvider;
  registry: PoolAddressesProviderRegistry;
  WrappedTokenGateway: WrappedTokenGateway;
  emissionManager: EmissionManager;
  rewardsController: RewardsController;
  rewardsVault: SignerWithAddress;
  hDaiMockV2: HTokenMock;
  hWethMockV2: HTokenMock;
  hHopeMockV2: HTokenMock;
  hEursMockV2: HTokenMock;
  pullRewardsStrategy: PullRewardsTransferStrategy;
  rewardToken: MintableERC20;
  rewardTokens: MintableERC20[];
  distributionEnd: number;
  hopePriceAggregator: tEthereumAddress;
  rewardPriceAggregator: tEthereumAddress;
  rewardsPriceAggregators: tEthereumAddress[];
}

let hardhatevmSnapshotId = '0x1';
const setHardhatevmSnapshotId = (id: string) => {
  hardhatevmSnapshotId = id;
};

const testEnv: TestEnv = {
  deployer: {} as SignerWithAddress,
  users: [] as SignerWithAddress[],
  poolAdmin: {} as SignerWithAddress,
  emergencyAdmin: {} as SignerWithAddress,
  riskAdmin: {} as SignerWithAddress,
  pool: {} as Pool,
  configurator: {} as PoolConfigurator,
  helpersContract: {} as HopeLendProtocolDataProvider,
  oracle: {} as HopeOracle,
  weth: {} as WETH9Mocked,
  hWETH: {} as HToken,
  dai: {} as MintableERC20,
  hDai: {} as HToken,
  variableDebtDai: {} as VariableDebtToken,
  stableDebtDai: {} as StableDebtToken,
  hUsdc: {} as HToken,
  usdc: {} as MintableERC20,
  hope: {} as MintableERC20,
  addressesProvider: {} as PoolAddressesProvider,
  registry: {} as PoolAddressesProviderRegistry,
  WrappedTokenGateway: {} as WrappedTokenGateway,
  emissionManager: {} as EmissionManager,
  rewardsController: {} as RewardsController,
  rewardsVault: {} as SignerWithAddress,
  hopeToken: {} as MintableERC20,
  hDaiMockV2: {} as HTokenMock,
  hWethMockV2: {} as HTokenMock,
  hHopeMockV2: {} as HTokenMock,
  hEursMockV2: {} as HTokenMock,
  pullRewardsStrategy: {} as PullRewardsTransferStrategy,
  rewardToken: {} as MintableERC20,
  rewardTokens: [],
  distributionEnd: 0,
  hopePriceAggregator: '',
  rewardPriceAggregator: '',
  rewardsPriceAggregators: [],
} as TestEnv;

export async function initializeMakeSuite() {
  const [_deployer, , , ...restSigners] = await getEthersSigners();
  const { incentivesRewardsVault } = await hre.getNamedAccounts();
  const deployer: SignerWithAddress = {
    address: await _deployer.getAddress(),
    signer: _deployer,
  };

  const rewardsVault: SignerWithAddress = {
    address: incentivesRewardsVault,
    signer: await hre.ethers.getSigner(incentivesRewardsVault),
  };

  for (const signer of restSigners) {
    testEnv.users.push({
      signer,
      address: await signer.getAddress(),
    });
  }
  testEnv.deployer = deployer;
  testEnv.poolAdmin = deployer;
  testEnv.emergencyAdmin = testEnv.users[1];
  testEnv.riskAdmin = testEnv.users[2];
  testEnv.pool = await getPool();

  testEnv.configurator = await getPoolConfiguratorProxy();

  testEnv.addressesProvider = await getPoolAddressesProvider();

  testEnv.registry = await getPoolAddressesProviderRegistry();
  testEnv.registry = await getPoolAddressesProviderRegistry();
  testEnv.oracle = await getHopeOracle();

  testEnv.helpersContract = await getHopeLendProtocolDataProvider();

  const allTokens = await testEnv.helpersContract.getAllHTokens();
  const hDaiAddress = allTokens.find((hToken) => hToken.symbol === 'aTestDAI')?.tokenAddress;
  const hUsdcAddress = allTokens.find((hToken) => hToken.symbol === 'aTestUSDC')?.tokenAddress;

  const hWEthAddress = allTokens.find((hToken) => hToken.symbol === 'aTestWETH')?.tokenAddress;

  const reservesTokens = await testEnv.helpersContract.getAllReservesTokens();

  const daiAddress = reservesTokens.find((token) => token.symbol === 'DAI')?.tokenAddress;
  const {
    variableDebtTokenAddress: variableDebtDaiAddress,
    stableDebtTokenAddress: stableDebtDaiAddress,
  } = await testEnv.helpersContract.getReserveTokensAddresses(daiAddress || '');
  const usdcAddress = reservesTokens.find((token) => token.symbol === 'USDC')?.tokenAddress;
  const hopeAddress = reservesTokens.find((token) => token.symbol === 'HOPE')?.tokenAddress;
  const wethAddress = reservesTokens.find((token) => token.symbol === 'WETH')?.tokenAddress;

  if (!hDaiAddress || !hWEthAddress || !hUsdcAddress) {
    console.error('Missing HToken address');
    process.exit(1);
  }
  if (!daiAddress || !usdcAddress || !hopeAddress || !wethAddress) {
    console.error('Missing Reserve address');
    process.exit(1);
  }

  testEnv.hDai = await getHToken(hDaiAddress);
  testEnv.variableDebtDai = await getVariableDebtToken(variableDebtDaiAddress);
  testEnv.stableDebtDai = await getStableDebtToken(stableDebtDaiAddress);
  testEnv.hUsdc = await getHToken(hUsdcAddress);
  testEnv.hWETH = await getHToken(hWEthAddress);

  testEnv.dai = await getMintableERC20(daiAddress);
  testEnv.usdc = await getMintableERC20(usdcAddress);
  testEnv.hope = await getMintableERC20(hopeAddress);
  testEnv.weth = await getWETHMocked(wethAddress);
  testEnv.WrappedTokenGateway = await getWrappedTokenGateway();

  // Added extra reward token
  await hre.deployments.deploy(`EXTRA${TESTNET_REWARD_TOKEN_PREFIX}`, {
    from: await _deployer.getAddress(),
    contract: 'MintableERC20',
    args: ['EXTRA', 'EXTRA', 18],
    log: true,
  });
  await hre.deployments.deploy(`EXTRA${TESTNET_PRICE_AGGR_PREFIX}`, {
    args: [parseEther('2')],
    from: await _deployer.getAddress(),
    log: true,
    contract: 'MockAggregator',
  });
  // Setup Incentives V2 environment
  const rewardTokens = await getSubTokensByPrefix(TESTNET_REWARD_TOKEN_PREFIX);
  const rewardsController = (await getIncentivesV2()) as any as RewardsController;

  const manager = await impersonateAddress(await rewardsController.EMISSION_MANAGER());

  await hre.ethers.provider.send('hardhat_setBalance', [manager.address, '0x56BC75E2D63100000']);

  testEnv.rewardsController = rewardsController.connect(manager.signer);

  testEnv.emissionManager = await getEmissionManager();

  await testEnv.emissionManager.setRewardsController(rewardsController.address);

  testEnv.rewardsVault = rewardsVault;
  testEnv.hopeToken = testEnv.hope;
  testEnv.hDaiMockV2 = await deployHTokenMock(rewardsController.address, 'hDaiV2');
  testEnv.hWethMockV2 = await deployHTokenMock(rewardsController.address, 'hWethV2');
  testEnv.hHopeMockV2 = await deployHTokenMock(rewardsController.address, 'hHopeV2');
  testEnv.hEursMockV2 = await deployHTokenMock(rewardsController.address, 'hEursV2', 2);
  testEnv.pullRewardsStrategy = (await getPullRewardsStrategy()) as PullRewardsTransferStrategy;
  testEnv.rewardToken = await getMintableERC20(rewardTokens[0].artifact.address);
  testEnv.rewardTokens = await bluebird.map(rewardTokens, ({ artifact }) =>
    getMintableERC20(artifact.address)
  );
  testEnv.distributionEnd = (await getBlockTimestamp()) + 1000 * 60 * 60;
  testEnv.hopePriceAggregator = (
    await hre.deployments.get(`HOPE${TESTNET_PRICE_AGGR_PREFIX}`)
  ).address;
  testEnv.rewardPriceAggregator = (
    await hre.deployments.get(`${rewardTokens[0].symbol}${TESTNET_PRICE_AGGR_PREFIX}`)
  ).address;
  testEnv.rewardsPriceAggregators = await bluebird.map(
    rewardTokens,
    async ({ symbol }) =>
      (
        await hre.deployments.get(`${symbol}${TESTNET_PRICE_AGGR_PREFIX}`)
      ).address
  );
  await waitForTx(
    await testEnv.hopeToken
      .connect(rewardsVault.signer)
      ['mint(address,uint256)'](rewardsVault.address, parseEther('60000000000'))
  );
  await waitForTx(
    await testEnv.rewardToken
      .connect(rewardsVault.signer)
      ['mint(address,uint256)'](rewardsVault.address, parseEther('200000000'))
  );
}

const setSnapshot = async () => {
  if (usingTenderly()) {
    setHardhatevmSnapshotId((await hre.tenderlyNetwork.getHead()) || '0x1');
    return;
  }
  setHardhatevmSnapshotId(await evmSnapshot());
};

const revertHead = async () => {
  if (usingTenderly()) {
    await hre.tenderlyNetwork.setHead(hardhatevmSnapshotId);
    return;
  }
  await evmRevert(hardhatevmSnapshotId);
};

export async function makeSuite(name: string, tests: (testEnv: TestEnv) => void): Promise<void> {
  describe(name, async () => {
    before(async () => {
      await setSnapshot();
    });
    tests(testEnv);
    after(async () => {
      await revertHead();
    });
  });
  afterEach(async () => {});
}

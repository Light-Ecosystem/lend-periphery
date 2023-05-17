import { HTokenMock } from './../../../types/HTokenMock.d';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

declare var hre: HardhatRuntimeEnvironment;

export const deployHTokenMock = async (
  incentivesController: string,
  slug: string,
  decimals = 18
): Promise<HTokenMock> => {
  const { deployer } = await hre.getNamedAccounts();
  const artifact = await hre.deployments.deploy(`${slug}-HTokenMock`, {
    contract: 'HTokenMock',
    from: deployer,
    args: [incentivesController, decimals],
    log: true,
  });
  return hre.ethers.getContractAt(artifact.abi, artifact.address);
};

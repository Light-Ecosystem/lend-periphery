// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.10;

import {ITransferStrategyBase} from './ITransferStrategyBase.sol';

/**
 * @title IPullRewardsTransferStrategy
 * @author HopeLend
 **/
interface IPullRewardsTransferStrategy is ITransferStrategyBase {
  /**
   * @return Address of the rewards vault
   */
  function getRewardsVault() external view returns (address);
}

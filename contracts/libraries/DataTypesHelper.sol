// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import {IERC20} from '@hopelend/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {DataTypes} from '@hopelend/core/contracts/protocol/libraries/types/DataTypes.sol';

/**
 * @title DataTypesHelper
 * @author HopeLend
 * @dev Helper library to track user current debt balance, used by WrappedTokenGateway
 */
library DataTypesHelper {
  /**
   * @notice Fetches the user current stable and variable debt balances
   * @param user The user address
   * @param reserve The reserve data object
   * @return The stable debt balance
   * @return The variable debt balance
   **/
  function getUserCurrentDebt(address user, DataTypes.ReserveData memory reserve)
    internal
    view
    returns (uint256, uint256)
  {
    return (
      IERC20(reserve.stableDebtTokenAddress).balanceOf(user),
      IERC20(reserve.variableDebtTokenAddress).balanceOf(user)
    );
  }
}

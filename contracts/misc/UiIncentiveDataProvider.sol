// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.10;

import {IERC20Detailed} from 'lend-core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IPoolAddressesProvider} from 'lend-core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from 'lend-core/contracts/interfaces/IPool.sol';
import {IncentivizedERC20} from 'lend-core/contracts/protocol/tokenization/base/IncentivizedERC20.sol';
import {UserConfiguration} from 'lend-core/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {DataTypes} from 'lend-core/contracts/protocol/libraries/types/DataTypes.sol';
import {IRewardsController} from '../rewards/interfaces/IRewardsController.sol';
import {IEACAggregatorProxy} from './interfaces/IEACAggregatorProxy.sol';
import {IUiIncentiveDataProvider} from './interfaces/IUiIncentiveDataProvider.sol';

contract UiIncentiveDataProvider is IUiIncentiveDataProvider {
  using UserConfiguration for DataTypes.UserConfigurationMap;

  function getFullReservesIncentiveData(IPoolAddressesProvider provider, address user)
    external
    view
    override
    returns (AggregatedReserveIncentiveData[] memory, UserReserveIncentiveData[] memory)
  {
    return (_getReservesIncentivesData(provider), _getUserReservesIncentivesData(provider, user));
  }

  function getReservesIncentivesData(IPoolAddressesProvider provider)
    external
    view
    override
    returns (AggregatedReserveIncentiveData[] memory)
  {
    return _getReservesIncentivesData(provider);
  }

  function _getReservesIncentivesData(IPoolAddressesProvider provider)
    private
    view
    returns (AggregatedReserveIncentiveData[] memory)
  {
    IPool pool = IPool(provider.getPool());
    address[] memory reserves = pool.getReservesList();
    AggregatedReserveIncentiveData[]
      memory reservesIncentiveData = new AggregatedReserveIncentiveData[](reserves.length);
    // Iterate through the reserves to get all the information from the (a/s/v) Tokens
    for (uint256 i = 0; i < reserves.length; i++) {
      AggregatedReserveIncentiveData memory reserveIncentiveData = reservesIncentiveData[i];
      reserveIncentiveData.underlyingAsset = reserves[i];

      DataTypes.ReserveData memory baseData = pool.getReserveData(reserves[i]);

      // Get hTokens rewards information
      // TODO: check that this is deployed correctly on contract and remove casting
      IRewardsController hTokenIncentiveController = IRewardsController(
        address(IncentivizedERC20(baseData.hTokenAddress).getIncentivesController())
      );
      RewardInfo[] memory aRewardsInformation;
      if (address(hTokenIncentiveController) != address(0)) {
        address[] memory hTokenRewardAddresses = hTokenIncentiveController.getRewardsByAsset(
          baseData.hTokenAddress
        );

        aRewardsInformation = new RewardInfo[](hTokenRewardAddresses.length);
        for (uint256 j = 0; j < hTokenRewardAddresses.length; ++j) {
          RewardInfo memory rewardInformation;
          rewardInformation.rewardTokenAddress = hTokenRewardAddresses[j];

          (
            rewardInformation.tokenIncentivesIndex,
            rewardInformation.emissionPerSecond,
            rewardInformation.incentivesLastUpdateTimestamp,
            rewardInformation.emissionEndTimestamp
          ) = hTokenIncentiveController.getRewardsData(
            baseData.hTokenAddress,
            rewardInformation.rewardTokenAddress
          );

          rewardInformation.precision = hTokenIncentiveController.getAssetDecimals(
            baseData.hTokenAddress
          );
          rewardInformation.rewardTokenDecimals = IERC20Detailed(
            rewardInformation.rewardTokenAddress
          ).decimals();
          rewardInformation.rewardTokenSymbol = IERC20Detailed(rewardInformation.rewardTokenAddress)
            .symbol();

          // Get price of reward token from Chainlink Proxy Oracle
          rewardInformation.rewardOracleAddress = hTokenIncentiveController.getRewardOracle(
            rewardInformation.rewardTokenAddress
          );
          rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
            rewardInformation.rewardOracleAddress
          ).decimals();
          rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
            rewardInformation.rewardOracleAddress
          ).latestAnswer();

          aRewardsInformation[j] = rewardInformation;
        }
      }

      reserveIncentiveData.aIncentiveData = IncentiveData(
        baseData.hTokenAddress,
        address(hTokenIncentiveController),
        aRewardsInformation
      );

      // Get vTokens rewards information
      IRewardsController vTokenIncentiveController = IRewardsController(
        address(IncentivizedERC20(baseData.variableDebtTokenAddress).getIncentivesController())
      );
      address[] memory vTokenRewardAddresses = vTokenIncentiveController.getRewardsByAsset(
        baseData.variableDebtTokenAddress
      );
      RewardInfo[] memory vRewardsInformation;

      if (address(vTokenIncentiveController) != address(0)) {
        vRewardsInformation = new RewardInfo[](vTokenRewardAddresses.length);
        for (uint256 j = 0; j < vTokenRewardAddresses.length; ++j) {
          RewardInfo memory rewardInformation;
          rewardInformation.rewardTokenAddress = vTokenRewardAddresses[j];

          (
            rewardInformation.tokenIncentivesIndex,
            rewardInformation.emissionPerSecond,
            rewardInformation.incentivesLastUpdateTimestamp,
            rewardInformation.emissionEndTimestamp
          ) = vTokenIncentiveController.getRewardsData(
            baseData.variableDebtTokenAddress,
            rewardInformation.rewardTokenAddress
          );

          rewardInformation.precision = vTokenIncentiveController.getAssetDecimals(
            baseData.variableDebtTokenAddress
          );
          rewardInformation.rewardTokenDecimals = IERC20Detailed(
            rewardInformation.rewardTokenAddress
          ).decimals();
          rewardInformation.rewardTokenSymbol = IERC20Detailed(rewardInformation.rewardTokenAddress)
            .symbol();

          // Get price of reward token from Chainlink Proxy Oracle
          rewardInformation.rewardOracleAddress = vTokenIncentiveController.getRewardOracle(
            rewardInformation.rewardTokenAddress
          );
          rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
            rewardInformation.rewardOracleAddress
          ).decimals();
          rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
            rewardInformation.rewardOracleAddress
          ).latestAnswer();

          vRewardsInformation[j] = rewardInformation;
        }
      }

      reserveIncentiveData.vIncentiveData = IncentiveData(
        baseData.variableDebtTokenAddress,
        address(vTokenIncentiveController),
        vRewardsInformation
      );

      // Get sTokens rewards information
      IRewardsController sTokenIncentiveController = IRewardsController(
        address(IncentivizedERC20(baseData.stableDebtTokenAddress).getIncentivesController())
      );
      address[] memory sTokenRewardAddresses = sTokenIncentiveController.getRewardsByAsset(
        baseData.stableDebtTokenAddress
      );
      RewardInfo[] memory sRewardsInformation;

      if (address(sTokenIncentiveController) != address(0)) {
        sRewardsInformation = new RewardInfo[](sTokenRewardAddresses.length);
        for (uint256 j = 0; j < sTokenRewardAddresses.length; ++j) {
          RewardInfo memory rewardInformation;
          rewardInformation.rewardTokenAddress = sTokenRewardAddresses[j];

          (
            rewardInformation.tokenIncentivesIndex,
            rewardInformation.emissionPerSecond,
            rewardInformation.incentivesLastUpdateTimestamp,
            rewardInformation.emissionEndTimestamp
          ) = sTokenIncentiveController.getRewardsData(
            baseData.stableDebtTokenAddress,
            rewardInformation.rewardTokenAddress
          );

          rewardInformation.precision = sTokenIncentiveController.getAssetDecimals(
            baseData.stableDebtTokenAddress
          );
          rewardInformation.rewardTokenDecimals = IERC20Detailed(
            rewardInformation.rewardTokenAddress
          ).decimals();
          rewardInformation.rewardTokenSymbol = IERC20Detailed(rewardInformation.rewardTokenAddress)
            .symbol();

          // Get price of reward token from Chainlink Proxy Oracle
          rewardInformation.rewardOracleAddress = sTokenIncentiveController.getRewardOracle(
            rewardInformation.rewardTokenAddress
          );
          rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
            rewardInformation.rewardOracleAddress
          ).decimals();
          rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
            rewardInformation.rewardOracleAddress
          ).latestAnswer();

          sRewardsInformation[j] = rewardInformation;
        }
      }

      reserveIncentiveData.sIncentiveData = IncentiveData(
        baseData.stableDebtTokenAddress,
        address(sTokenIncentiveController),
        sRewardsInformation
      );
    }

    return (reservesIncentiveData);
  }

  function getUserReservesIncentivesData(IPoolAddressesProvider provider, address user)
    external
    view
    override
    returns (UserReserveIncentiveData[] memory)
  {
    return _getUserReservesIncentivesData(provider, user);
  }

  function _getUserReservesIncentivesData(IPoolAddressesProvider provider, address user)
    private
    view
    returns (UserReserveIncentiveData[] memory)
  {
    IPool pool = IPool(provider.getPool());
    address[] memory reserves = pool.getReservesList();

    UserReserveIncentiveData[] memory userReservesIncentivesData = new UserReserveIncentiveData[](
      user != address(0) ? reserves.length : 0
    );

    for (uint256 i = 0; i < reserves.length; i++) {
      DataTypes.ReserveData memory baseData = pool.getReserveData(reserves[i]);

      // user reserve data
      userReservesIncentivesData[i].underlyingAsset = reserves[i];

      IRewardsController hTokenIncentiveController = IRewardsController(
        address(IncentivizedERC20(baseData.hTokenAddress).getIncentivesController())
      );
      if (address(hTokenIncentiveController) != address(0)) {
        // get all rewards information from the asset
        address[] memory hTokenRewardAddresses = hTokenIncentiveController.getRewardsByAsset(
          baseData.hTokenAddress
        );
        UserRewardInfo[] memory aUserRewardsInformation = new UserRewardInfo[](
          hTokenRewardAddresses.length
        );
        for (uint256 j = 0; j < hTokenRewardAddresses.length; ++j) {
          UserRewardInfo memory userRewardInformation;
          userRewardInformation.rewardTokenAddress = hTokenRewardAddresses[j];

          userRewardInformation.tokenIncentivesUserIndex = hTokenIncentiveController
            .getUserAssetIndex(
              user,
              baseData.hTokenAddress,
              userRewardInformation.rewardTokenAddress
            );

          userRewardInformation.userUnclaimedRewards = hTokenIncentiveController
            .getUserAccruedRewards(user, userRewardInformation.rewardTokenAddress);
          userRewardInformation.rewardTokenDecimals = IERC20Detailed(
            userRewardInformation.rewardTokenAddress
          ).decimals();
          userRewardInformation.rewardTokenSymbol = IERC20Detailed(
            userRewardInformation.rewardTokenAddress
          ).symbol();

          // Get price of reward token from Chainlink Proxy Oracle
          userRewardInformation.rewardOracleAddress = hTokenIncentiveController.getRewardOracle(
            userRewardInformation.rewardTokenAddress
          );
          userRewardInformation.priceFeedDecimals = IEACAggregatorProxy(
            userRewardInformation.rewardOracleAddress
          ).decimals();
          userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
            userRewardInformation.rewardOracleAddress
          ).latestAnswer();

          aUserRewardsInformation[j] = userRewardInformation;
        }

        userReservesIncentivesData[i].hTokenIncentivesUserData = UserIncentiveData(
          baseData.hTokenAddress,
          address(hTokenIncentiveController),
          aUserRewardsInformation
        );
      }

      // variable debt token
      IRewardsController vTokenIncentiveController = IRewardsController(
        address(IncentivizedERC20(baseData.variableDebtTokenAddress).getIncentivesController())
      );
      if (address(vTokenIncentiveController) != address(0)) {
        // get all rewards information from the asset
        address[] memory vTokenRewardAddresses = vTokenIncentiveController.getRewardsByAsset(
          baseData.variableDebtTokenAddress
        );
        UserRewardInfo[] memory vUserRewardsInformation = new UserRewardInfo[](
          vTokenRewardAddresses.length
        );
        for (uint256 j = 0; j < vTokenRewardAddresses.length; ++j) {
          UserRewardInfo memory userRewardInformation;
          userRewardInformation.rewardTokenAddress = vTokenRewardAddresses[j];

          userRewardInformation.tokenIncentivesUserIndex = vTokenIncentiveController
            .getUserAssetIndex(
              user,
              baseData.variableDebtTokenAddress,
              userRewardInformation.rewardTokenAddress
            );

          userRewardInformation.userUnclaimedRewards = vTokenIncentiveController
            .getUserAccruedRewards(user, userRewardInformation.rewardTokenAddress);
          userRewardInformation.rewardTokenDecimals = IERC20Detailed(
            userRewardInformation.rewardTokenAddress
          ).decimals();
          userRewardInformation.rewardTokenSymbol = IERC20Detailed(
            userRewardInformation.rewardTokenAddress
          ).symbol();

          // Get price of reward token from Chainlink Proxy Oracle
          userRewardInformation.rewardOracleAddress = vTokenIncentiveController.getRewardOracle(
            userRewardInformation.rewardTokenAddress
          );
          userRewardInformation.priceFeedDecimals = IEACAggregatorProxy(
            userRewardInformation.rewardOracleAddress
          ).decimals();
          userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
            userRewardInformation.rewardOracleAddress
          ).latestAnswer();

          vUserRewardsInformation[j] = userRewardInformation;
        }

        userReservesIncentivesData[i].vTokenIncentivesUserData = UserIncentiveData(
          baseData.variableDebtTokenAddress,
          address(hTokenIncentiveController),
          vUserRewardsInformation
        );
      }

      // stable debt token
      IRewardsController sTokenIncentiveController = IRewardsController(
        address(IncentivizedERC20(baseData.stableDebtTokenAddress).getIncentivesController())
      );
      if (address(sTokenIncentiveController) != address(0)) {
        // get all rewards information from the asset
        address[] memory sTokenRewardAddresses = sTokenIncentiveController.getRewardsByAsset(
          baseData.stableDebtTokenAddress
        );
        UserRewardInfo[] memory sUserRewardsInformation = new UserRewardInfo[](
          sTokenRewardAddresses.length
        );
        for (uint256 j = 0; j < sTokenRewardAddresses.length; ++j) {
          UserRewardInfo memory userRewardInformation;
          userRewardInformation.rewardTokenAddress = sTokenRewardAddresses[j];

          userRewardInformation.tokenIncentivesUserIndex = sTokenIncentiveController
            .getUserAssetIndex(
              user,
              baseData.stableDebtTokenAddress,
              userRewardInformation.rewardTokenAddress
            );

          userRewardInformation.userUnclaimedRewards = sTokenIncentiveController
            .getUserAccruedRewards(user, userRewardInformation.rewardTokenAddress);
          userRewardInformation.rewardTokenDecimals = IERC20Detailed(
            userRewardInformation.rewardTokenAddress
          ).decimals();
          userRewardInformation.rewardTokenSymbol = IERC20Detailed(
            userRewardInformation.rewardTokenAddress
          ).symbol();

          // Get price of reward token from Chainlink Proxy Oracle
          userRewardInformation.rewardOracleAddress = sTokenIncentiveController.getRewardOracle(
            userRewardInformation.rewardTokenAddress
          );
          userRewardInformation.priceFeedDecimals = IEACAggregatorProxy(
            userRewardInformation.rewardOracleAddress
          ).decimals();
          userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
            userRewardInformation.rewardOracleAddress
          ).latestAnswer();

          sUserRewardsInformation[j] = userRewardInformation;
        }

        userReservesIncentivesData[i].sTokenIncentivesUserData = UserIncentiveData(
          baseData.stableDebtTokenAddress,
          address(hTokenIncentiveController),
          sUserRewardsInformation
        );
      }
    }

    return (userReservesIncentivesData);
  }
}

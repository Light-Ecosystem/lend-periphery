// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from 'lend-core/contracts/dependencies/openzeppelin/contracts/Ownable.sol';
import {IStreamable} from './interfaces/IStreamable.sol';
import {IAdminControlledEcosystemReserve} from './interfaces/IAdminControlledEcosystemReserve.sol';
import {IHopeLendEcosystemReserveController} from './interfaces/IHopeLendEcosystemReserveController.sol';
import {IERC20} from 'lend-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

contract HopeLendEcosystemReserveController is Ownable, IHopeLendEcosystemReserveController {
  /**
   * @notice Constructor.
   * @param hopeLendGovShortTimelock The address of the HopeLend's governance executor, owning this contract
   */
  constructor(address hopeLendGovShortTimelock) {
    transferOwnership(hopeLendGovShortTimelock);
  }

  /// @inheritdoc IHopeLendEcosystemReserveController
  function approve(
    address collector,
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    IAdminControlledEcosystemReserve(collector).approve(token, recipient, amount);
  }

  /// @inheritdoc IHopeLendEcosystemReserveController
  function transfer(
    address collector,
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    IAdminControlledEcosystemReserve(collector).transfer(token, recipient, amount);
  }

  /// @inheritdoc IHopeLendEcosystemReserveController
  function createStream(
    address collector,
    address recipient,
    uint256 deposit,
    IERC20 tokenAddress,
    uint256 startTime,
    uint256 stopTime
  ) external onlyOwner returns (uint256) {
    return
      IStreamable(collector).createStream(
        recipient,
        deposit,
        address(tokenAddress),
        startTime,
        stopTime
      );
  }

  /// @inheritdoc IHopeLendEcosystemReserveController
  function withdrawFromStream(
    address collector,
    uint256 streamId,
    uint256 funds
  ) external onlyOwner returns (bool) {
    return IStreamable(collector).withdrawFromStream(streamId, funds);
  }

  /// @inheritdoc IHopeLendEcosystemReserveController
  function cancelStream(address collector, uint256 streamId) external onlyOwner returns (bool) {
    return IStreamable(collector).cancelStream(streamId);
  }
}

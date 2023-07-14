// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {HopeLendEcosystemReserve} from '../../treasury/HopeLendEcosystemReserve.sol';

contract MockHopeLendEcosystemReserveV2 is HopeLendEcosystemReserve {
  bool public updated = true;

  function getRevision() internal pure override returns (uint256) {
    return 0x2;
  }
}

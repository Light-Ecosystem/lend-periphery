// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

contract HTokenMock {
  uint256 internal _userBalance;
  uint256 internal _totalSupply;
  uint256 internal immutable _decimals;

  // hack to be able to test event from Distribution manager properly
  event AssetConfigUpdated(
    address indexed asset,
    address indexed reward,
    uint256 emission,
    uint256 distributionEnd,
    uint256 assetIndex
  );

  constructor(uint256 decimals) {
    _decimals = decimals;
  }

  function setUserBalanceAndSupply(uint256 userBalance, uint256 totalSupply) public {
    _userBalance = userBalance;
    _totalSupply = totalSupply;
  }

  function getScaledUserBalanceAndSupply(address) external view returns (uint256, uint256) {
    return (_userBalance, _totalSupply);
  }

  function scaledTotalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function cleanUserState() external {
    _userBalance = 0;
    _totalSupply = 0;
  }

  function decimals() external view returns (uint256) {
    return _decimals;
  }
}

const cp = require('child_process');

module.exports = {
  configureYulOptimizer: true,
  skipFiles: [
    './mocks',
    './misc/UiPoolDataProvider.sol',
    './misc/WalletBalanceProvider.sol',
    './misc/interfaces/',
  ],
  onCompileComplete: function () {
    console.log('onCompileComplete hook');
    cp.execSync('. ./setup-test-env.sh', { stdio: 'inherit' });
  },
};

require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-chai-matchers");
require("@nomiclabs/hardhat-ethers");
require("dotenv").config();


// Custom Hardhat Tasks
task("show-balance", async () => {
  const showBalance = require("./scripts/showBalance");
  return showBalance();
});

task("deploy-contract", async () => {
  const deployContract = require("./scripts/deployContract");
  return deployContract();
});

module.exports = {
  mocha: {
    timeout: 3600000,
  },
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 500,
      },
    },
  },
  defaultNetwork: "testnet",
  networks: {
    testnet: {
      url: process.env.TESTNET_ENDPOINT,
      accounts: [process.env.TESTNET_OPERATOR_PRIVATE_KEY],
    },
    // previewnet: {
    //   url: process.env.PREVIEWNET_ENDPOINT,
    //   accounts: [process.env.PREVIEWNET_OPERATOR_PRIVATE_KEY],
    // },
    // mainnet: {
    //   url: process.env.MAINNET_ENDPOINT,
    //   accounts: [process.env.MAINNET_OPERATOR_PRIVATE_KEY],
    // },
  },
};

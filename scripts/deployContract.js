const { ethers } = require("hardhat");

module.exports = async () => {

  console.log("Deployment initiated...")
  const [wallet] = await ethers.getSigners();
  console.log("Deployment in progress... Please wait")
  const HealthRecordManagementContractFactory = await ethers.getContractFactory("HealthRecordManagement", wallet);

  const healthRecordManagement = await HealthRecordManagementContractFactory.deploy();
  // Wait for deployment to complete
  await healthRecordManagement.deployed();
  const contractAddress = healthRecordManagement.address;

  console.log(`HealthRecordManagement Contract Deployed To: ${contractAddress} By - ContractOwner : ${wallet.address}`);
  return contractAddress;
};

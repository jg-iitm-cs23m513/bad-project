const hre = require("hardhat");
const { expect } = require("chai");

describe("HealthRecordManagement", function () {
  let contract;
  let owner, doctor1, doctor2, patient;

  beforeEach(async function () {
    [owner, doctor1, doctor2, patient] = await hre.ethers.getSigners();
    const ContractFactory = await hre.ethers.getContractFactory("HealthRecordManagement", owner);
    contract = await ContractFactory.deploy();
    await contract.deployed();
  });

  it("should deploy the contract successfully", async function () {
    expect(contract.address).to.properAddress;
  });

  it("should allow admin to register a health service provider", async function () {
    await contract.connect(owner).registerHealthCareServiceProvider(doctor1.address);
    const isRegistered = await contract.registeredHealthServiceProviders(doctor1.address);
    expect(isRegistered).to.be.true;
  });

 

});

const { expect } = require("chai");
const { ethers } = require("@nomicfoundation/hardhat-ethers");

describe("BabeToken", function () {
  let BabeToken, babeToken, owner, addr1, addr2;

  beforeEach(async function () {
    // Deploy the contract before each test
    BabeToken = await ethers.getContractFactory("BabeToken");
    [owner, addr1, addr2] = await ethers.getSigners();
    babeToken = await BabeToken.deploy();
    await babeToken.deployed();
  });

  it("Should assign the total supply of tokens to the owner", async function () {
    const ownerBalance = await babeToken.balanceOf(owner.address);
    expect(await babeToken.totalSupply()).to.equal(ownerBalance);
  });

  it("Should transfer tokens between accounts", async function () {
    await babeToken.transfer(addr1.address, 50);
    expect(await babeToken.balanceOf(addr1.address)).to.equal(50);
  });

  it("Should fail if sender doesn’t have enough tokens", async function () {
    await expect(
      babeToken.connect(addr1).transfer(addr2.address, 1)
    ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
  });
});

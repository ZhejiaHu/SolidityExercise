const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Splitwise basic test", function () {
    it("Basic test: Triangle", async function () {
        this.timeout(5000);
        const MyContract = await ethers.getContractFactory("Splitwise");
        const split_wise = await MyContract.deploy();
        const [account1, account2, account3] = await ethers.getSigners();
        const addresses = ([account1, account2, account3]).map((signer) => signer.address)
        await split_wise.connect(account1).add_IOU(addresses[1], 3);
        await split_wise.connect(account2).add_IOU(addresses[2], 4);
        await split_wise.connect(account3).add_IOU(addresses[0], 5);
        const result = await split_wise.connect(account1).lookup(addresses[0], addresses[1]);
       expect(result).to.equal(0);
    });
});
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Splitwise basic test: With update", function () {
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

    it("Basic test: Larger round", async function() {
        this.timeout(5000);
        const MyContract = await ethers.getContractFactory("Splitwise");
        const split_wise = await MyContract.deploy();
        const [account1, account2, account3, account4, account5] = await ethers.getSigners();
        const accounts = [account1, account2, account3, account4, account5];
        const addresses = accounts.map((signer) => signer.address);
        for (let i = 0; i < 5; i++) {
            await split_wise.connect(accounts[i]).add_IOU(addresses[(i + 1) % 5], (i + 1));
        }
        for (let i = 0; i < 5; i++) {
            const result = await split_wise.connect(accounts[i]).lookup(addresses[i], addresses[(i + 1) % 5]);
            expect(result).to.equal(i);
        }
    });

    it("Basic test: Larger round and non-monotone sequence", async function() {
        this.timeout(5000);
        const MyContract = await ethers.getContractFactory("Splitwise");
        const split_wise = await MyContract.deploy();
        const [account1, account2, account3, account4, account5] = await ethers.getSigners();
        const accounts = [account1, account2, account3, account4, account5];
        const addresses = accounts.map((signer) => signer.address);
        const owes = [7, 9, 8, 2, 4];
        const anses = [5, 7, 6, 0, 2];
        for (let i = 0; i < 5; i++) {
            await split_wise.connect(accounts[i]).add_IOU(addresses[(i + 1) % 5], owes[i]);
        }
        for (let i = 0; i < 5; i++) {
            const result = await split_wise.connect(accounts[i]).lookup(addresses[i], addresses[(i + 1) % 5]);
            expect(result).to.equal(anses[i]);
        }
    });

    it("Basic test: Larger round, non-monotone sequence, and multiple rounds", async function() {
        this.timeout(5000);
        const MyContract = await ethers.getContractFactory("Splitwise");
        const split_wise = await MyContract.deploy();
        const [account1, account2, account3, account4, account5, account6, account7] = await ethers.getSigners();
        const account_group_1 = [account1, account2, account3, account4];
        const account_group_2 = [account5, account6, account7];
        const address_group_1 = account_group_1.map((signer) => signer.address);
        const address_group_2 = account_group_2.map((signer) => signer.address);
        const owes_1 = [9, 16, 7, 20], anses_1 = [2, 9, 0, 13];
        const owes_2 = [21, 21, 21], anses_2 = [0, 0, 0];
        for (let i = 0; i < 4; i++) {
            await split_wise.connect(account_group_1[i]).add_IOU(address_group_1[(i + 1) % 4], owes_1[i]);
        }
        for (let i = 0; i < 3; i++) {
            await split_wise.connect(account_group_2[i]).add_IOU(address_group_2[(i + 1) % 3], owes_2[i]);
        }
        for (let i = 0; i < 4; i++) {
            const result = await split_wise.connect(account_group_1[i]).lookup(address_group_1[i], address_group_1[(i + 1) % 4]);
            expect(result).to.equal(anses_1[i]);
        }
        for (let i = 0; i < 3; i++) {
            const result = await split_wise.connect(account_group_2[i]).lookup(address_group_2[i], address_group_2[(i + 1) % 3]);
            expect(result).to.equal(anses_2[i]);
        }
    });

    it("Basic test: Larger round, non-monotone sequence, and multiple rounds 2", async function() {
        this.timeout(5000);
        const MyContract = await ethers.getContractFactory("Splitwise");
        const split_wise = await MyContract.deploy();
        const [account1, account2, account3, account4, account5, account6, account7, account8, account9] = await ethers.getSigners();
        const account_group_1 = [account1, account2, account3, account4];
        const account_group_2 = [account5, account6, account7, account8, account9];
        const address_group_1 = account_group_1.map((signer) => signer.address);
        const address_group_2 = account_group_2.map((signer) => signer.address);
        const owes_1 = [9, 16, 7, 20], anses_1 = [2, 9, 0, 13];
        const owes_2 = [21, 21, 21, 19, 31], anses_2 = [2, 2, 2, 0, 12];
        for (let i = 0; i < 4; i++) {
            await split_wise.connect(account_group_1[i]).add_IOU(address_group_1[(i + 1) % 4], owes_1[i]);
        }
        for (let i = 0; i < 5; i++) {
            await split_wise.connect(account_group_2[i]).add_IOU(address_group_2[(i + 1) % 5], owes_2[i]);
        }
        for (let i = 0; i < 4; i++) {
            const result = await split_wise.connect(account_group_1[i]).lookup(address_group_1[i], address_group_1[(i + 1) % 4]);
            expect(result).to.equal(anses_1[i]);
        }
        for (let i = 0; i < 5; i++) {
            const result = await split_wise.connect(account_group_2[i]).lookup(address_group_2[i], address_group_2[(i + 1) % 5]);
            expect(result).to.equal(anses_2[i]);
        }
    });

    it("Basic: Two rounds share common vertex", async function() {
        this.timeout(5000);
        const MyContract = await ethers.getContractFactory("Splitwise");
        const split_wise = await MyContract.deploy();
        const [account1, account2, account3, account4, account5] = await ethers.getSigners();
        const accounts = [account1, account2, account3, account4, account5];
        const addresses = accounts.map((signer) => signer.address);
        const edges = [
            [0, 1, 3, 0],
            [1, 2, 4, 1],
            [2, 0, 5, 2],
            [0, 3, 20, 13],
            [3, 4, 7, 0],
            [4, 0, 37, 30]
        ]
        for (let edge of edges) {
            const from = edge[0], to = edge[1], amount = edge[2];
            await split_wise.connect(accounts[from]).add_IOU(addresses[to], amount);
        }
        for (let edge of edges) {
            const from = edge[0], to = edge[1], ans = edge[3];
            const result = await split_wise.connect(accounts[from]).lookup(addresses[from], addresses[to]);
            expect(result).to.equal(ans);
        }
    })

    it("Basic: Two rounds share common edge", async function() {
        this.timeout(5000);
        const MyContract = await ethers.getContractFactory("Splitwise");
        const split_wise = await MyContract.deploy();
        const [account1, account2, account3, account4, account5] = await ethers.getSigners();
        const accounts = [account1, account2, account3, account4, account5];
        const addresses = accounts.map((signer) => signer.address);
        const edges = [
            [0, 1, 8, 0],
            [1, 2, 4, 0],
            [2, 0, 5, 1],
            [1, 3, 20, 16],
            [3, 4, 7, 3],
            [4, 0, 37, 33]
        ]

        for (let edge of edges) {
            const from = edge[0], to = edge[1], amount = edge[2];
            await split_wise.connect(accounts[from]).add_IOU(addresses[to], amount);
            console.log(await split_wise.connect(accounts[0]).debug())
        }
        console.log(await split_wise.connect(accounts[0]).get_matrix())
        for (let edge of edges) {
            const from = edge[0], to = edge[1], ans = edge[3];
            const result = await split_wise.connect(accounts[from]).lookup(addresses[from], addresses[to]);
            expect(result).to.equal(ans);
        }
    })


});

describe("Splitwise basic test: Without update", function () {
    it("Basic: One single line", async function() {
        this.timeout(5000);
        const MyContract = await ethers.getContractFactory("Splitwise");
        const split_wise = await MyContract.deploy();
        const [account1, account2, account3, account4, account5, account6, account7] = await ethers.getSigners();
        const accounts = [account1, account2, account3, account4, account5, account6, account7];
        const addresses = accounts.map((signer) => signer.address);
        for (let i = 0; i < 6; i++) {
            await split_wise.connect(accounts[i]).add_IOU(addresses[(i + 1) % 7], (i + 1));
        }
        for (let i = 0; i < 6; i++) {
            const result = await split_wise.connect(accounts[i]).lookup(addresses[i], addresses[(i + 1) % 7]);
            expect(result).to.equal(i + 1);
        }
    });

    it("Basic: Directed Acyclic Graph", async function() {
        this.timeout(5000);
        const MyContract = await ethers.getContractFactory("Splitwise");
        const split_wise = await MyContract.deploy();
        const [account1, account2, account3, account4, account5, account6, account7] = await ethers.getSigners();
        const accounts = [account1, account2, account3, account4, account5, account6, account7];
        const addresses = accounts.map((signer) => signer.address);
        const edges = [
            [0, 1, 7],
            [0, 2, 100],
            [0, 5, 3],
            [1, 6, 20],
            [2, 6, 1000],
            [3, 4, 1],
            [3, 5, 55],
            [4, 6, 11],
            [5, 6, 547]
        ];
        for (let edge of edges) {
            const from = edge[0], to = edge[1], amount = edge[2];
            await split_wise.connect(accounts[from]).add_IOU(addresses[to], amount);
        }
        for (let edge of edges) {
            const from = edge[0], to = edge[1], amount = edge[2];
            const result = await split_wise.connect(accounts[from]).lookup(addresses[from], addresses[to]);
            expect(result).to.equal(amount);
        }
    });

    it("Basic: Combined structure", async function() {
        this.timeout(5000);
        const MyContract = await ethers.getContractFactory("Splitwise");
        const split_wise = await MyContract.deploy();
        const [account1, account2, account3, account4, account5, account6, account7] = await ethers.getSigners();
        const accounts = [account1, account2, account3, account4, account5, account6, account7];
        const addresses = accounts.map((signer) => signer.address);

        const edges = [
            [0, 1, 7],
            [0, 2, 9],
            [1, 2, 101],
            [2, 3, 919]
        ]
        for (let edge of edges) {
            const from = edge[0], to = edge[1], amount = edge[2];
            await split_wise.connect(accounts[from]).add_IOU(addresses[to], amount);
        }

        for (let i = 4; i < 6; i++) {
            await split_wise.connect(accounts[i]).add_IOU(addresses[i + 1], 7);
        }
        for (let edge of edges) {
            const from = edge[0], to = edge[1], amount = edge[2];
            const result = await split_wise.connect(accounts[from]).lookup(addresses[from], addresses[to]);
            expect(result).to.equal(amount);
        }
        for (let i = 4; i < 6; i++) {
            const result = await split_wise.connect(accounts[i]).lookup(addresses[i], addresses[i + 1]);
            expect(result).to.equal(7);
        }

    })
})
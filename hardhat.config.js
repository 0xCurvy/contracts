require("@nomicfoundation/hardhat-toolbox");

require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.6.11",
    paths: {
        sources: "zk-verifiers",
    },
    defaultNetwork: "sepolia",
    networks: {
        sepolia: {
            url: process.env.RPC_URL,
            accounts: [process.env.DEPLOYER_PK],
        },
        hardhat: {
            chainId: 1337,
            verify: false,
            accounts: {
                mnemonic:
                    "test test test test test test test test test test test junk",
                count: 10,
            },
        },
    },
};

import hardhatIgnitionViemPlugin from "@nomicfoundation/hardhat-ignition-viem";
import hardhatToolboxViemPlugin from "@nomicfoundation/hardhat-toolbox-viem";
import hardhatVerifyPlugin from "@nomicfoundation/hardhat-verify";
import { configVariable, type HardhatUserConfig } from "hardhat/config";


const isDevenv = () => {
  return process.argv.includes("devenv");
}

const config: HardhatUserConfig = {
  plugins: [hardhatToolboxViemPlugin, hardhatIgnitionViemPlugin, hardhatVerifyPlugin],
  paths: {
    sources: isDevenv() ? 'devenv' : 'contracts'
  },
  solidity: {
    npmFilesToBuild: ["@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol"],
    profiles: {
      default: {
        version: "0.8.28",
      },
      createx: {
        version: "0.8.23",
      },
      production: {
        version: "0.8.28",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    },
  },
  networks: {
    anvil: {
      url: "http://127.0.0.1:8545",
      type: "http",
    },
    hardhat: {
      type: "edr-simulated",
      chainType: "l1",
      mining: {
        auto: false,
        interval: 1000,
      },
    },
    localhost: {
      type: "http",
      url: "http://127.0.0.1:8545",
    },
    hardhatMainnet: {
      type: "edr-simulated",
      chainType: "l1",
    },
    hardhatOp: {
      type: "edr-simulated",
      chainType: "op",
    },
    sepolia: {
      type: "http",
      chainType: "l1",
      url: configVariable("ALCHEMY_API_KEY", "https://eth-sepolia.g.alchemy.com/v2/{variable}"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
    arbitrum: {
      type: "http",
      url: configVariable("ALCHEMY_API_KEY", "https://arb-mainnet.g.alchemy.com/v2/{variable}"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
    ethereum: {
      type: "http",
      url: configVariable("ALCHEMY_API_KEY", "https://eth-mainnet.g.alchemy.com/v2/{variable}"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
    base: {
      type: "http",
      url: configVariable("ALCHEMY_API_KEY", "https://base-mainnet.g.alchemy.com/v2/{variable}"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
    optimism: {
      type: "http",
      url: configVariable("ALCHEMY_API_KEY", "https://opt-mainnet.g.alchemy.com/v2/{variable}"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
    polygon: {
      type: "http",
      url: configVariable("ALCHEMY_API_KEY", "https://polygon-mainnet.g.alchemy.com/v2/{variable}"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
    bsc: {
      type: "http",
      url: configVariable("ALCHEMY_API_KEY", "https://bnb-mainnet.g.alchemy.com/v2/{variable}"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
    linea: {
      type: "http",
      url: configVariable("ALCHEMY_API_KEY", "https://linea-mainnet.g.alchemy.com/v2/{variable}"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
    gnosis: {
      type: "http",
      url: configVariable("ALCHEMY_API_KEY", "https://gnosis-mainnet.g.alchemy.com/v2/{variable}"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
  },
  verify: {
    etherscan: {
      apiKey: configVariable("ETHERSCAN_API_KEY"),
    },
  },
};

export default config;

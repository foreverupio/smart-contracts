import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { INFURA_API_KEY, FORKING_BLOCK_NUMMBER, getNetworkConfig } from "./config";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
      // https://hardhat.org/hardhat-network/docs/guides/forking-other-networks
      forking: {
        url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
        blockNumber: FORKING_BLOCK_NUMMBER,
        enabled: false,
      },
    },
    mainnet: getNetworkConfig("mainnet"),
    polygon: getNetworkConfig("polygon"),
    sepolia: getNetworkConfig("sepolia"),
    mumbai: getNetworkConfig("mumbai"),
  },
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100000,
      },
    },
  },
};

export default config;

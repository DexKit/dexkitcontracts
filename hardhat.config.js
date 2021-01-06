const privateKeys =  [process.env.PRIVATE_KEY];
const  providerOrUrl = `https://ropsten.infura.io/v3/${infuraProjectId}`;


module.exports = {
    defaultNetwork: "ropsten",
    networks: {
      hardhat: {
      },
      ropsten: {
        url: providerOrUrl,
        accounts: privateKeys
      }
    },
    solidity: {
      version: "0.5.15",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    },
    paths: {
      sources: "./contracts",
      tests: "./test",
      cache: "./cache",
      artifacts: "./artifacts"
    },
    mocha: {
      timeout: 20000
    }
  }
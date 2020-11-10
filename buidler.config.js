
const HDWalletProvider = require('@truffle/hdwallet-provider');
require('dotenv').config();
const infuraProjectId = process.env.INFURA_PROJECT_ID;

usePlugin("@nomiclabs/buidler-etherscan");
const privateKeys =  [process.env.PRIVATE_KEY];
const  providerOrUrl = `https://ropsten.infura.io/v3/${infuraProjectId}`;

module.exports = {
    networks: {
        ropsten: {
               url: `https://ropsten.infura.io/v3/${infuraProjectId}`,
               provider: () => new HDWalletProvider(
                privateKeys, providerOrUrl
                ),
                networkId: 3,
                gasPrice: 10e9
             }
      },
    solc: {
        version: "0.6.12"
      },
    etherscan: {
      // Your API key for Etherscan
      // Obtain one at https://etherscan.io/
      apiKey: "STWA5GG71NEJ7QZETMM7Y6MS9B322BHPV6"
    }
  };

const HDWalletProvider = require('@truffle/hdwallet-provider');
require('dotenv').config();
const infuraProjectId = process.env.INFURA_PROJECT_ID;


const privateKeys =  [process.env.PRIVATE_KEY];
const  providerOrUrl = `https://ropsten.infura.io/v3/${infuraProjectId}`;

module.exports = {
  networks: {
    development: {
      protocol: 'http',
      host: 'localhost',
      port: 8545,
      gas: 5000000,
      gasPrice: 5e9,
      networkId: '*',
    },
    ropsten: {
           provider: () => new HDWalletProvider(
            privateKeys, providerOrUrl
            ),
            networkId: 3,
            gasPrice: 10e9
         }
  },
};

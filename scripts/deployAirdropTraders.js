
// erc20 contract used to deploy traders
const ERC20Contract = ''

const { ether } = require('@openzeppelin/test-helpers');

const amount = ether('1');


async function main() {
    // We get the contract to deploy
    const AirdropTraders = await ethers.getContractFactory("AirdropTraders");
    console.log("Deploying AirdropTradders...");
    const aidropTraders = await AirdropTraders.deploy();
    await aidropTraders.deployed();
    const accounts = await ethers.provider.listAccounts();
    const owner = accounts[0];
    console.log("Airdrop traders deployed to:", aidropTraders.address);
    await this.airdropContract.setCampaignTraders(ERC20Contract, amount, ether('0'), {from:owner})
    // For Ropsten test purpose
    await aidropTraders.setCampaignStatus(ERC20Contract, true);
    // add trader to contract
    const traders = JSON.parse(fs.readFileSync('scripts/traders.json', 'utf8'));
    const tradersBatch = traders.length/10;
    for (let index = 0; index < 10; index++) {
      await aidropTraders.addTraders(traders.slice(index*tradersBatch, (index+1)*tradersBatch-1 ));
  }  
    


}
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
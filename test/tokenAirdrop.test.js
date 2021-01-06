const { accounts, contract } = require('@openzeppelin/test-environment');
const { expect } = require('chai');

// Import utilities from Test Helpers
const { BN, expectEvent, expectRevert, send, ether, time, balance } = require('@openzeppelin/test-helpers');
const { BigNumber } = require('ethers');

// Load compiled artifacts
const AirdropTraders = contract.fromArtifact('AirdropTraders');
const DexKit = contract.fromArtifact('DexKit');

function onePercent(value) {
  return value.mul(new BN('100')).div(new BN('10000'));
}

// Start test block
describe('AirdropTraders', function () {
  const [owner, user1, user2, user3, ...users] = accounts;
  const amount = ether('1');
  const price = new BN('350');
  // It's 7 days, we put it 8 to make sure time elapsed
  const saleDuration = time.duration.days(8);
  const cap = ether('1').mul(new BN('10000000'));
  const airdropAmount = ether('20');
  const initialSaleTime = Math.round(Date.now() / 1000) + 3600;

  beforeEach(async function () {
    this.contract = await DexKit.new({ from: owner });
    const currentTime = Number((await time.latest())) + 10;
    this.airdropContract = await AirdropTraders.new( { from: owner })
    // creating campaign 
    this.airdropContract.setCampaignTraders(this.contract.address, amount, ether('0'), {from:owner})
    this.contract.transfer(this.airdropContract.address, airdropAmount, { from: owner });
  });

  
   it('User can claim tokens', async function () {
    // active campaign
    await this.airdropContract.setCampaignStatus(this.contract.address, true, {from:owner});
    // add trader to contract
    await this.airdropContract.addTraders([user1], {from:owner});

    await this.airdropContract.claimAirdrop(this.contract.address, {from:user1})
    const balanceTokens = await this.contract.balanceOf(user1);
    expect(balanceTokens.toString()).to.be.equal(amount.toString());
    const isTokenTrader = await this.airdropContract.isTokenTrader(this.contract.address, user1, {from:user1});
   
    expect(isTokenTrader).to.be.true;
  });

  it('User cannot claim tokens when not on list', async function () {
    // active campaign
    await this.airdropContract.setCampaignStatus(this.contract.address, true, {from:owner});
    // add trader to contract
    await this.airdropContract.addTraders([user1], {from:owner});

    await expectRevert(this.airdropContract.claimAirdrop(this.contract.address, {from:user2}), "AirdropTraders: trader not on list");

    const isTokenTrader = await this.airdropContract.isTokenTrader(this.contract.address, user2, {from:user1});
    expect(isTokenTrader).to.be.false;
    const isTrader = await this.airdropContract.isTrader(user2, {from:user1})
   
    expect(isTrader).to.be.false;
  });

  it('User cannot claim tokens if campaign is not active', async function () {
    // add trader to contract
    await this.airdropContract.addTraders([user1], {from:owner});

    await expectRevert(this.airdropContract.claimAirdrop(this.contract.address, {from:user1}), "AirdropTraders: campaign is not active");

  });

  it('User cannot claim tokens twice', async function () {
    // active campaign
    await this.airdropContract.setCampaignStatus(this.contract.address, true, {from:owner});
    // add trader to contract
    await this.airdropContract.addTraders([user1], {from:owner});
    await this.airdropContract.claimAirdrop(this.contract.address, {from:user1})
    await expectRevert(this.airdropContract.claimAirdrop(this.contract.address, {from:user1}), "AirdropTraders: already airdroped");
  });

  it('User is on trader list when added to traders', async function () {
    // active campaign
    await this.airdropContract.setCampaignStatus(this.contract.address, true, {from:owner});
    // add trader to contract
    await this.airdropContract.addTraders([user1], {from:owner});

    const isTrader = await this.airdropContract.isTrader(user1, {from:user1})
   
    expect(isTrader).to.be.true;
  
  });

  it('User is not on trader list when removed', async function () {
    // active campaign
    await this.airdropContract.setCampaignStatus(this.contract.address, true, {from:owner});
    // add trader to contract
    await this.airdropContract.addTraders([user1], {from:owner});
      // remove trader from contract
    await this.airdropContract.removeTraders([user1], {from:owner});

    const isTrader = await this.airdropContract.isTrader(user1, {from:user1})
   
    expect(isTrader).to.be.false;
  
  });
   // Test case
   it('Dev can release tokens if needed', async function () {
   
    const balanceKitBefore = await this.contract.balanceOf(owner);
    await this.airdropContract.releaseToken(this.contract.address, { from: owner });
    const balanceKitAfter = await this.contract.balanceOf(owner);
    // if no tokens distributed, this will be equal to cap
    expect(balanceKitAfter.sub(balanceKitBefore).toString()).to.be.eq(airdropAmount.toString());
  });

  it('User can claim tokens if it holds amount', async function () {

    await this.airdropContract.setCampaignTraders(this.contract.address, amount, amount, {from:owner})
    this.contract.transfer(user1, amount, { from: owner });
    // active campaign
    await this.airdropContract.setCampaignStatus(this.contract.address, true, {from:owner});
    // add trader to contract
    await this.airdropContract.addTraders([user1], {from:owner});

    await this.airdropContract.claimAirdrop(this.contract.address, {from:user1})
    const balanceTokens = await this.contract.balanceOf(user1);
    expect(balanceTokens.toString()).to.be.equal(amount.mul(new BN(2)).toString());
    const isTokenTrader = await this.airdropContract.isTokenTrader(this.contract.address, user1, {from:user1});
   
    expect(isTokenTrader).to.be.true;
  });

  it('User cannot claim tokens if not holds minimal amount', async function () {

    await this.airdropContract.setCampaignTraders(this.contract.address, amount, amount, {from:owner})
    // active campaign
    await this.airdropContract.setCampaignStatus(this.contract.address, true, {from:owner});
    // add trader to contract
    await this.airdropContract.addTraders([user1], {from:owner});
    await expectRevert(this.airdropContract.claimAirdrop(this.contract.address, {from:user1}), "AirdropTraders: not meet minimal holding");
  
  });



  
});
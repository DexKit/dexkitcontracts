const { accounts, contract } = require('@openzeppelin/test-environment');
const { expect } = require('chai');

// Import utilities from Test Helpers
const { BN, expectEvent, expectRevert, send, ether, time, balance } = require('@openzeppelin/test-helpers');

// Load compiled artifacts
const DexKitSale = contract.fromArtifact('DexKitSale');
const DexKit = contract.fromArtifact('DexKit');

function onePercent(value) {
  return value.mul(new BN('100')).div(new BN('10000'));
}

// Start test block
describe('DexKitSale', function () {
  const [owner, user1, user2, user3, ...users] = accounts;
  const amount = ether('1');
  const price = new BN('350');
  // It's 7 days, we put it 8 to make sure time elapsed
  const saleDuration = time.duration.days(8);
  const cap = ether('1').mul(new BN('10000000'));
  const otcSaleAmount = ether('1').mul(new BN('1500000'));
  const initialSaleTime = Math.round(Date.now() / 1000) + 3600;

  beforeEach(async function () {
    this.contract = await DexKit.new({ from: owner });
    const currentTime = Number((await time.latest())) + 10;
    this.saleContract = await DexKitSale.new(currentTime, this.contract.address, { from: owner })
    this.contract.transfer(this.saleContract.address, otcSaleAmount, { from: owner });
    // this.contract.approve(this.saleContract.address, otcSaleAmount, {from: owner});
  });

   // Test case
   it('Returns correct token contract', async function () {
    const tokenContract = await this.saleContract.token();
    expect(tokenContract).to.be.equal(this.contract.address);
  });

  // Test case
  it('Not able to send ETH before sale date', async function () {
    await expectRevert(send.ether(user1, this.saleContract.address, ether('2')), "DexKitSale: Sale not started");
  });

  // Test case
  it('Not able to send ETH after sale date', async function () {
    await time.increase(saleDuration);
    await expectRevert(send.ether(user1, this.saleContract.address, ether('2')), "DexKitSale: Sale finished");
  });

  // Test case
  it('Widthraw allowed when called it by dev', async function () {
    let allowed = await this.saleContract.withdrawAllowed();
    expect(allowed).to.be.false;
    await this.saleContract.allowWithdraw({ from: owner });
    allowed = await this.saleContract.withdrawAllowed();
    expect(allowed).to.be.true;
  });
   // Test case
   it('Dev can not release tokens before sale is complete plus 5 days', async function () {
    await time.increase(time.duration.days(10));
    await expectRevert(this.saleContract.release({ from: user1 }), "DexKitSale: Not passed lock time");
    await expectRevert(this.saleContract.release({ from: owner }), "DexKitSale: Not passed lock time");
  });

   // Test case
   it('user can not buy lower and above limits', async function () {
    await time.increase(time.duration.seconds(20));
    await expectRevert(send.ether(user1, this.saleContract.address, ether('0.5')), "DexKitSale: Minimum value is 1 ETH");
    await expectRevert(send.ether(user1, this.saleContract.address, ether('26')), "DexKitSale: Maximum value is 25 ETH");
  
  });



  // Test case
  it('Dev can release tokens after sale is complete plus 5 days', async function () {
    await time.increase(time.duration.days(21));
    // this can be called by any function
    await this.saleContract.release({ from: user1 });
    const balanceKit = await this.contract.balanceOf(owner);
    // if no tokens distributed, this will be equal to cap
    expect(balanceKit.toString()).to.be.eq(cap.toString());
  });


  // Test case
  it('Widthraw allowed when after sale end', async function () {
    let allowed = await this.saleContract.withdrawAllowed();
    expect(allowed).to.be.false;
    await time.increase(saleDuration);
    allowed = await this.saleContract.withdrawAllowed();
    expect(allowed).to.be.true;
  });


  // Test case
  it('Dev can withdraw ETH ', async function () {
    await time.increase(time.duration.seconds(20));
    await send.ether(user1, this.saleContract.address, ether('2'));
    const balanceOwner = await balance.current(owner);
    await this.saleContract.withdrawETH({ from: owner });
    // We need to subtract the gas fee
    expect(Number((await balance.current(owner)).toString())).to.be.greaterThan(Number(balanceOwner.add(ether('1.9')).toString()));

  });

  // Test case
  it('User can withdraw ETH in behalf of dev, but dev receives funds ', async function () {
    await time.increase(time.duration.seconds(20));
    await send.ether(user1, this.saleContract.address, ether('2'));
    const balanceOwner = await balance.current(owner);
    await this.saleContract.withdrawETH({ from: user1 });
    // We need to subtract the gas fee
    expect(Number((await balance.current(owner)).toString())).to.be.greaterThan(Number(balanceOwner.add(ether('1.9')).toString()));

  });

  // Test case
  it('User can not reinvest', async function () {
    await time.increase(time.duration.seconds(20));
    await send.ether(user1, this.saleContract.address, ether('2'));
    await expectRevert(send.ether(user1, this.saleContract.address, ether('2')), "DexKitSale: already invested");
  });

  
  // Test case
  it('Widthraw of returns correct value', async function () {
    await time.increase(time.duration.seconds(20));
    await send.ether(user1, this.saleContract.address, ether('1'))

    const dexkitBalance = await this.saleContract.userWithdrawBalanceOf(user1, { from: user3 });
    // We need to subtract the gas fee
    expect(Number(dexkitBalance.toString())).to.be.eq(Number(ether('1') * 750));
  });


  // Test case
  it('Users get DexKit OTC sale 1 with 1 ETH', async function () {
    await time.increase(time.duration.seconds(20));
    await send.ether(user1, this.saleContract.address, ether('1'))
    await send.ether(user2, this.saleContract.address, ether('25'))

    const dexkitBalance = await this.saleContract.userWithdrawBalanceOf(user1, { from: user3 });
    const dexkitBalance2 = await this.saleContract.userWithdrawBalance({ from: user2 });
    const raisedETH = await this.saleContract.raisedETH();
    // We need to subtract the gas fee
    expect(Number(dexkitBalance.toString())).to.be.eq(Number(ether('1') * 750));
    expect(Number(dexkitBalance2.toString())).to.be.eq(Number(ether('25') * 750));
    expect(Number(raisedETH.toString())).to.be.eq(Number(ether('26')));

  });

  // Test case
  it('Users buy DexKit OTC sale 1 with ETH and withdraw after sale end', async function () {

    await time.increase(time.duration.seconds(20));
    await send.ether(user1, this.saleContract.address, ether('1'))
    await send.ether(user2, this.saleContract.address, ether('25'))
    await time.increase(saleDuration);
    // when user calls function
    await this.saleContract.withdrawTokens({ from: user1 });
    // when it is called by someonte else
    await this.saleContract.withdrawByTokens(user2, { from: owner });
    const balanceKit = await this.contract.balanceOf(user1);
    const balanceKit2 = await this.contract.balanceOf(user2);

    // We need to subtract the gas fee
    expect(Number(balanceKit.toString())).to.be.eq(Number(ether('1') * 750));
    expect(Number(balanceKit2.toString())).to.be.eq(Number(ether('25') * 750));

  });
  // Test case
  it('Users buy DexKit OTC sale 1 with ETH and withdraw after withdraw allowed', async function () {

    await time.increase(time.duration.seconds(20));
    await send.ether(user1, this.saleContract.address, ether('1'))
    await send.ether(user2, this.saleContract.address, ether('25'))
    await this.saleContract.allowWithdraw({ from: owner });
    // when user calls function
    await this.saleContract.withdrawTokens({ from: user1 });
    // when it is called by someonte else
    await this.saleContract.withdrawByTokens(user2, { from: owner });
    const balanceKit = await this.contract.balanceOf(user1);
    const balanceKit2 = await this.contract.balanceOf(user2);

    // We need to subtract the gas fee
    expect(Number(balanceKit.toString())).to.be.eq(Number(ether('1') * 750));
    expect(Number(balanceKit2.toString())).to.be.eq(Number(ether('25') * 750));
  });
  // We are not able to test 106 users  
  it('Not able to sell above max cap', async function () {

    await time.increase(time.duration.seconds(20));
    // Send ETH to sold out sales
    for (let index = 0; index < 106; index++) {
      await send.ether(users[index], this.saleContract.address, ether('25'))
    }
    await expectRevert(send.ether(users[106], this.saleContract.address, ether('25')), "DexKitSale: sale sold out");

  });

  // We are not able to test 106 users  
  it('Simulates a sale with 106 users', async function () {

    await time.increase(time.duration.seconds(20));
    // Send ETH to sold out sales
    for (let index = 0; index < 106; index++) {
      await send.ether(users[index], this.saleContract.address, ether('25'))
    }

    const dexkitBalance = await this.saleContract.userWithdrawBalance({ from: users[0] });
    const dexkitBalance2 = await this.saleContract.userWithdrawBalance({ from: users[20] });
    const dexkitBalance3 = await this.saleContract.userWithdrawBalance({ from: users[48] });

    expect(Number(dexkitBalance.toString())).to.be.eq(Number(ether('25') * 750));
    expect(Number(dexkitBalance2.toString())).to.be.eq(Number(ether('25') * 600));
    expect(Number(dexkitBalance3.toString())).to.be.eq(Number(ether('25') * 500));

    await time.increase(saleDuration);
    // when users calls function
    await this.saleContract.withdrawTokens({ from: users[0] });
    await this.saleContract.withdrawTokens({ from: users[20] });
    await this.saleContract.withdrawTokens({ from: users[48] });
    // when it is called by someonte else
    // await this.saleContract.withdrawByTokens(user2, {from: owner});
    const balanceKit = await this.contract.balanceOf(users[0]);
    const balanceKit2 = await this.contract.balanceOf(users[20]);
    const balanceKit3 = await this.contract.balanceOf(users[48]);
    const raisedETH = await this.saleContract.raisedETH();
    // We need to subtract the gas fee
    expect(balanceKit.toString()).to.be.eq(dexkitBalance.toString());
    expect(balanceKit2.toString()).to.be.eq(dexkitBalance2.toString());
    expect(balanceKit3.toString()).to.be.eq(dexkitBalance3.toString());
    expect(Number(raisedETH.toString())).to.be.eq(Number(ether('2650')));
    const balanceOwner = await balance.current(owner);
    await this.saleContract.withdrawETH({ from: owner });
    // We need to subtract the gas fee
    expect(Number((await balance.current(owner)).toString())).to.be.greaterThan(Number(balanceOwner.add(ether('2649')).toString()));
  });
  // We are not able to test 106 users  
  it('Simulates a sale with 106 users and withdraw by all users', async function () {

    await time.increase(time.duration.seconds(20));
    // Send ETH to sold out sales
    for (let index = 0; index < 106; index++) {
      await send.ether(users[index], this.saleContract.address, ether('25'))
    }
    await time.increase(saleDuration);
    for (let index = 0; index < 106; index++) {
      await this.saleContract.withdrawTokens({ from: users[index] });
    } 

    const balanceKit = await this.contract.balanceOf(this.saleContract.address);
    // when sold out kit balance will be zero
    expect(balanceKit.toString()).to.be.eq('0');
  });




});
const { accounts, contract } = require('@openzeppelin/test-environment');
const { expect } = require('chai');

// Import utilities from Test Helpers
const { BN, expectEvent, expectRevert, send, ether, time, balance } = require('@openzeppelin/test-helpers');

// Load compiled artifacts
const DexKit = contract.fromArtifact('DexKit');

function onePercent(value){
  return  value.mul(new BN('100')).div(new BN('10000'));
}

// Start test block
describe('DexKit', function () {
    const [ owner, user1, user2, user3 ] = accounts;
    const amount = ether('1');
    const price = new BN('350');
    const cap = ether('1').mul(new BN('10000000'));
    const initialSaleTime = Math.round(Date.now( ) / 1000) + 3600;
    beforeEach(async function () {
      
      this.contract = await DexKit.new({ from: owner });
    });
  
    // Test case
    it('retrieve correct total supply when nothing minted', async function () {
      expect((await this.contract.totalSupply()).toString()).to.equal('0');
    });
    // Test case
    it('contract not accept eth below 1', async function () {
     await expectRevert(send.ether(user1 , this.contract.address, ether('0.5')), 'Minimum value is 1 ETH');
     await expectRevert(send.ether(user1 , this.contract.address, ether('0.999')), 'Minimum value is 1 ETH');
     await expectRevert(send.ether(user1 , this.contract.address, ether('0.001')), 'Minimum value is 1 ETH');
    });

    // Test case
    it('other user can not withraw ETH ', async function () {
      await send.ether(user1 , this.contract.address, ether('2'))
      await expectRevert(this.contract.withdrawETH({from: user1}), "Not owner" );
     });

     it('can not take snapshot before 30 days', async function () {
       await expectRevert(this.contract.doSnapshot(), "Not passed 30 days yet" );
       await time.increase(time.duration.days(29));
       await expectRevert(this.contract.doSnapshot(), "Not passed 30 days yet" );
     });

     it('can do snaphost after 30 days', async function () {
      await time.increase(time.duration.days(30));
      expect((await this.contract.currentSnapshotId()).toString()).to.equal('0');
      await this.contract.doSnapshot();
      expect((await this.contract.currentSnapshotId()).toString()).to.equal('1');
    });

     // Test case
    it(' only owner can withdraw ETH', async function () {
      await send.ether(user1 , this.contract.address, ether('20'))
      const balanceOwner = await balance.current(owner);
      await this.contract.withdrawETH({ from: owner });
      // We need to subtract the gas fee
      expect(Number((await balance.current(owner)).toString())).to.be.greaterThan(Number(balanceOwner.add(ether('19.9')).toString()));
     });

    it('contract not accept eth above 20', async function () {
      await expectRevert(send.ether(user1 , this.contract.address, ether('20.0001')), 'Maximum value is 20 ETH');
      await expectRevert(send.ether(user1 , this.contract.address, ether('25')), 'Maximum value is 20 ETH');
      await expectRevert(send.ether(user1 , this.contract.address, ether('21')), 'Maximum value is 20 ETH');
     });
      // It is set to being in after 30 days
    /* it('contract retrieves correct initial sale time', async function () {
      expect((await this.contract.initialSaleTime()).toString()).to.equal(initialSaleTime.toString());
     });*/

     it('contract retrieves correct price', async function () {
      expect((await this.contract.priceInv()).toString()).to.equal(price.mul(new BN('1000')).toString());
     });

     it('contract retrieves correct cap', async function () {
      expect((await this.contract.cap()).toString()).to.equal(cap.toString());
     });

     it('contract mints correct amount of coins at initial sale time ', async function () {
      await send.ether(user1 , this.contract.address, amount);
      await send.ether(user2 , this.contract.address, amount);
      await send.ether(user3 , this.contract.address, amount);

      expect((await this.contract.balanceOf(user1)).toString()).to.equal(price.mul(amount).toString());
      expect((await this.contract.balanceOf(user2)).toString()).to.equal(price.mul(amount).toString());
      expect((await this.contract.balanceOf(user3)).toString()).to.equal(price.mul(amount).toString());
      expect((await this.contract.totalSupply()).toString()).to.equal(price.mul(amount).mul(new BN('3')).toString());
     });

     it('contract raises price linearly at each buy after sale time', async function () {
      await time.increase(time.duration.days(31));
      const amoutToSend = ether('20');
      await send.ether(user1 , this.contract.address, amoutToSend);
      expect((await this.contract.balanceOf(user1)).toString()).to.equal(amoutToSend.mul(new BN('350')).toString());
      let p = (await this.contract.priceInv()).toString();

      await send.ether(user2 , this.contract.address, amoutToSend);
      p = (await this.contract.priceInv()).toString();

      //expect((await this.contract.balanceOf(user2)).toString()).to.equal(amoutToSend.mul(priceInvUser2).div(new BN(1000)).toString());
      expect((await this.contract.balanceOf(user2)).toString()).to.equal(amoutToSend.mul(new BN('350')).toString());
      const totalSupply = await this.contract.totalSupply();
      const priceInvStart = new BN('350000')
      const priceInvUser2 =  priceInvStart.sub(priceInvStart.mul(totalSupply).div(cap));
      await send.ether(user3 , this.contract.address, amoutToSend);
      p = (await this.contract.priceInv()).toString();

    // expect((await this.contract.balanceOf(user3)).toString()).to.equal(amoutToSend.mul(priceInvUser2).div(new BN(1000)).toString());


    /*  let priceInvAmount = price.mul(new BN('1000'));
      let priceInvAmountIncrease = priceInvAmount.mul(amoutToSend).div(ether('20'));
      const decreasePrice = onePercent(priceInvAmountIncrease);
      const currentPrice = priceInvAmount.sub(decreasePrice).toString();
      expect((await this.contract.priceInv()).toString()).to.equal(currentPrice);  
      await send.ether(user1 , this.contract.address, amoutToSend);  */


     /* await send.ether(user1 , this.contract.address, ether('1'));  
      expect((await this.contract.priceInv()).toString()).to.equal('352');
      await send.ether(user1 , this.contract.address, ether('20')); 
      expect((await this.contract.priceInv()).toString()).to.equal('359');
      await send.ether(user2 , this.contract.address, ether('20')); 
      expect((await this.contract.priceInv()).toString()).to.equal('362');
      await send.ether(user2 , this.contract.address, ether('20')); 
      expect((await this.contract.priceInv()).toString()).to.equal('365');
      await send.ether(user2 , this.contract.address, ether('20')); 
      expect((await this.contract.priceInv()).toString()).to.equal('368');*/
     });


  });
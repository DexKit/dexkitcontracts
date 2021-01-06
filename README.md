# DEXKIT Smart contracts

This project is composed of following smartcontracts:

 - DexKit.sol: DexKit Token contract 
 - BITTOKEN.sol: Bittoken Token contract
 - DexKitSale.sol : DexKit smartcontract used for sale distribution 
 - KitTokenTimelock.sol : DexKit smartcontract used for affiliates lock KIT to unlock NFT marketplace and ERC20 exchange
 - KitTokenTimelockFactory.sol : DexKit smartcontract to track all affiliates
 - AirdropTraders.sol : Contract to distribute rewards to users that used Powered By DexKit 
 - FeeDistributor.sol : Contract to distribute fees collected by affiliates in a trustless way
 - StakingRewards.sol : Contract to distribute Staking rewards based on DexKit Token onchain snapshots


# Scripts

Scripts used to deploy smartcontracts and fetch traders from 0x tracker


 # TESTING

Before run to install all dependencies

`yarn`

For testing DexKit sale smartcontracts run:

`yarn test-sale`




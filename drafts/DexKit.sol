// contracts/DexKit.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract DexKit is  ERC20Capped, ERC20Snapshot {

    using SafeMath for uint256;
     // timestamp for next snapshot
    uint256 private _snapshotTimestamp;

    uint256 private _currentSnapshotId;

    uint256 private _initialSaleTime;
    // ETH at 350 USD gives this price at 10 USD 
    // 1/0.035 = 33 we round it to 35
    // multiply by 10000 to have more price scaling
    uint256 private _priceInv = 350000;

    uint256 private _priceInvStart = 350000;
    // Final price till cap is reached
    // 1/0.1 = 0.1 ETH per Kit
    uint256 private _priceInvFinal = 100000;
    

    address payable private _wallet;
    // Used to development purposes
    address payable private _DEV_WALLET = 0xc1004fF9aBD758742dc50997de61016fE29EdDFE;
    // Used to marketing purposes
    address payable private _MARKETING_WALLET = 0x1DbA5844e67Cd01cf601E47872Dbe438726E584a;
    // Used to liquidity/exchange purposes during 3 years
    address payable private _LIQ_WALLET = 0x1a5D1ca1D9a0c6A1DB0d01b596b6729D88E95718;

    // Founder wallet
    address payable private _FOUNDER_WALLET = 0xd4CeA40761CaB3B05Bba3A7C2CD3124C5FAEa53b;

    constructor() public ERC20("DexKit", "KIT") ERC20Capped(10000000 *10**18)  {
        _snapshotTimestamp = block.timestamp;
        _wallet = _msgSender();
        _initialSaleTime = block.timestamp + 30 days; 
    }

     /**
     * @dev Returns current mint inverted price 
     */
    function priceInv() public view returns (uint256) {
        return _priceInv;
    }

       /**
     * @dev Returns wallet which distributes funds
     */
    function wallet() public view returns (address) {
        return _wallet;
    }

     /**
     * @dev Returns development wallet
     */
    function developmentWallet() public view returns (address) {
        return _DEV_WALLET;
    }

     /**
     * @dev Returns liquidity wallet
     */
    function liquidityWallet() public view returns (address) {
        return _LIQ_WALLET;
    }

    /**
     * @dev Returns marketing wallet
     */
    function marketingWallet() public view returns (address) {
        return _MARKETING_WALLET;
    }

      /**
     * @dev Returns founder wallet
     */
    function founderWallet() public view returns (address) {
        return _FOUNDER_WALLET;
    }

     /**
     * @dev Returns initial sale time
     */
    function initialSaleTime() public view returns (uint256) {
        return _initialSaleTime;
    }
  
    /**
    *  @dev When receive ETH mint tokens to sender. Number of minted tokens decreases lineary based on total supply and cap after initial sale time is expired
    *
    *
     */
    receive() external payable {
        require(msg.value >= 1 ether, "Minimum value is 1 ETH");
        require(msg.value <= 100 ether, "Maximum value is 100 ETH");

        uint256 amountToMint = msg.value*_priceInv.div(10000);
        if(block.timestamp > _initialSaleTime){
          // Inverted price decreases linearly with total supply increasing
           _priceInv = _priceInvStart.sub(_priceInvStart.mul(totalSupply()).div(cap()));
           // If price is lower than final price we set it as final price till as supply is all filled
           if(_priceInv < _priceInvFinal){
             _priceInv = _priceInvFinal;
            }
        }
         
        _mint(_msgSender(), amountToMint);
    }

    /**
    * @dev Do snapshot each 30 days if triggered. Snapshots are used for governance and rewards distribution
    */
    function doSnapshot() public returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _snapshotTimestamp + 30 days, "Not passed 30 days yet");
        // update snapshot timestamp with new time
        _snapshotTimestamp = block.timestamp;

        _currentSnapshotId = _snapshot();
        return _currentSnapshotId;
    }

    /**
    * @dev Return current snapshot id
    */
    function currentSnapshotId() public view returns (uint256) {
        return _currentSnapshotId;

    }

     function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._beforeTokenTransfer(from, to, amount);
    }
      /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual override(ERC20, ERC20Snapshot){
        super._burn(account, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Snapshot){
         super._mint(account, amount);
    }

     /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override(ERC20, ERC20Snapshot){
         super._transfer(sender, recipient, amount);
    }

    /**
    *
    * @dev Return ETH raised to wallets. 
     */
    function withdrawETH() public {
      require(_wallet == _msgSender(), "Not owner" );
      uint256 amount = address(this).balance;
      require(amount > 0, "No ETH to Withraw");
      _DEV_WALLET.transfer(amount.mul(125).div(1000));
      _MARKETING_WALLET.transfer(amount.mul(125).div(1000));    
      _FOUNDER_WALLET.transfer(amount.mul(50).div(1000));
      _LIQ_WALLET.transfer(amount.mul(700).div(1000));      
    }

}
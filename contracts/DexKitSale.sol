// contracts/DexKit.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
*
* DexKit Sale contract, used to distribute tokens by contract address.
* This sale as 3 rounds
* OTC Price 1 = 750 KIT per ETH --> capped to 400 ETH
* OTC Price 2 = 600 KIT per ETH --> capped to 750 ETH
* OTC Price 3 = 500 KIT per ETH --> capped to 1500 ETH
* Max Cap is 2650 ETH
* How it works? User send ETH to contract, min 1 ETH, max 25 ETH, the otc price is computed according to raised amount
* User can only interact with smartcontract only one time, after that smartcontract not allow to send ETH again
* 
* Sale opens at 14 of November UTC time 00:00:00
*/

contract DexKitSale is  ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
 
    uint256 private _startSaleTime;

    uint256 private _endSaleTime;

    uint256 private _raisedETH;

    uint256 private _priceOTC1 = 750;
    // Cap with price with OTC1
    uint256 private _thresholdOTC1 = 400 ether;

    uint256 private _priceOTC2 = 600;
    // Threshold OTC 2 here is cappedOTC1 plus cappedOTC2
    uint256 private _thresholdOTC2 = 1150 ether;

    uint256 private _priceOTC3 = 500;

    uint256 private _maxCap = 2650 ether;

    bool private _isWithdrawAllowed = false;

    IERC20 private _token;

    mapping (address => uint256) private _withdrawBalances;
    

    address payable private _wallet;


    constructor(uint256 startSaleTime, IERC20 token) public{
        require(startSaleTime > block.timestamp, "DexKitSale: Start sale time needs to be bigger than current time");
        _startSaleTime = startSaleTime;
        _endSaleTime = startSaleTime + 7 days;
        _wallet = msg.sender;
        _token = token;
    }


    /**
     * @dev Returns wallet which receives OTC funds
     */
    function wallet() public view returns (address) {
        return _wallet;
    }

    /**
     * @dev Returns token
     */
    function token() public view returns (address) {
        return address(_token);
    }

    /**
     * @dev Returns sale starting time
     */
    function startSaleTime() public view returns (uint256) {
        return _startSaleTime;
    }

    /**
     * @dev Returns end sale time
     */
    function endSaleTime() public view returns (uint256) {
        return _endSaleTime;
    }

    /**
     * @dev Returns max cap
     */
    function maxCap() public view returns (uint256) {
        return _maxCap;
    }

    /**
     * @dev Returns raised ETH
     */
    function raisedETH() public view returns (uint256) {
        return _raisedETH;
    }

     /**
     * @dev user withdraw balance
     */
    function userWithdrawBalance() public view returns (uint256) {
        return _withdrawBalances[msg.sender];
    }

     /**
     * @dev user withdraw balance
     */
    function userWithdrawBalanceOf(address user) public view returns (uint256) {
        return _withdrawBalances[user];
    }


    /**
     * @dev check if withdraw is allowed already
     */
    function withdrawAllowed() public view returns (bool) {
        return _isWithdrawAllowed || block.timestamp > endSaleTime();
    }


    /**
    *  @dev When receive ETH register tokens to be withdraw later after sale
    *
    *
     */
    receive() external payable {
        require(block.timestamp > startSaleTime(), "DexKitSale: Sale not started");
        require(block.timestamp < endSaleTime(), "DexKitSale: Sale finished");
        require(msg.value >= 1 ether, "DexKitSale: Minimum value is 1 ETH");
        require(msg.value <= 25 ether, "DexKitSale: Maximum value is 25 ETH");
        require(_withdrawBalances[msg.sender] == 0, "DexKitSale: already invested");
        require(!_isWithdrawAllowed, "DexKitSale: Withdraw was enabled");
        uint256 amount = msg.value;
        // Price it starts at OTC1 price
        uint256 price = _priceOTC1;

        _raisedETH = _raisedETH.add(amount);
        require(_raisedETH <= _maxCap, "DexKitSale: sale sold out");
        // If first cap is reached, OTC price is updated to round 2
        if(_raisedETH > _thresholdOTC1){
            price = _priceOTC2;
        }
        // If second cap is reached, OTC price is updated to round 3
        if(_raisedETH > _thresholdOTC2){
            price = _priceOTC3;
        }
       
        _withdrawBalances[msg.sender] = _withdrawBalances[msg.sender].add(amount.mul(price));
        emit Boughted(msg.sender, amount, price);
    }
    /**
    * @dev call this if you want to allow withdraw before sale time, this could happen if sold out happen.
    * It is recommended allow withdraw only after Uniswap pool is set
    *   
     */
    function allowWithdraw() public onlyOwner{
        _isWithdrawAllowed = true;
    }

      /**
    *
    * @dev User can withdraw after end of sale time or if withdraw is allowed
     */
    function withdrawTokens() external nonReentrant {
      require(block.timestamp > endSaleTime()  || _isWithdrawAllowed, "DexKitSale: Sale not finished");
      uint256 amount = _withdrawBalances[msg.sender];
      require(amount > 0, "DexKitSale: Amount needs to be bigger than zero");
       _withdrawBalances[msg.sender] = 0;
      _token.safeTransfer(msg.sender, amount);
      emit Withdrawed(msg.sender, amount);
    }

    /**
     *
     * @dev call this if user not know how to call withdraw tokens function, this withdraw tokens to user in their behalf
     */
    function withdrawByTokens(address user) external nonReentrant {
      require(block.timestamp > endSaleTime() || _isWithdrawAllowed, "DexKitSale: Sale not finished");
      uint256 amount = _withdrawBalances[user];
      require(amount > 0, "DexKitSale: Amount needs to be bigger than zero");
      _withdrawBalances[user] = 0;
      _token.safeTransfer(user, amount);
      emit Withdrawed(user, amount);
    }

    /**
    *
    * @dev Return ETH raised to project. Dev can withdraw at any time, part of OTC value is needed to setup Uniswap Liquidity, 
    * so it is needed to withdraw before users
     */
    function withdrawETH() public {
      uint256 amount = address(this).balance;
      require(amount > 0, "No ETH to Withdraw");
      _wallet.transfer(amount);
    }
      /**
     * @notice Transfers tokens held by sale smartcontract back to dev after 5 days of sale finished. Transfer tokens back to user 
     * before call this function
     */
    function release() public {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= endSaleTime() + 5 days, "DexKitSale: Not passed lock time");

        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "DexKitSale: no tokens to release");

        _token.safeTransfer(_wallet, amount);
    }

    event Withdrawed(address indexed user, uint256 amount);
    event Boughted(address indexed user, uint256 amount, uint256 price);
}
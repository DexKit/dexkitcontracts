// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
/**
 * @title FeeDistributor
 * @dev 
 */
contract FeeDistributor is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private _kitShares = 2500;
    uint256 private _projectShares = 7500;
    uint256 private _totalShares = 10000;



    address payable _feeProjectAddress;
    address payable _feeKitAddress;

    /**
     * @dev 
     */
    constructor () public payable {
      
    }

    function setFeeProjectAddress(address payable feeProjectAddress) public onlyOwner{
        _feeProjectAddress = feeProjectAddress;
    }

    function setFeeKitAddress(address payable feeKitAddress) public onlyOwner{
        _feeKitAddress = feeKitAddress;
    }

    /**
     * @dev 
     */
    function releaseETH() public {
        uint256 balance = address(this).balance;
        require(balance > 0, "FeeDistributor: no balance to distribute");

        uint256 kitBalance = balance.mul(_kitShares).div(_totalShares);
        uint256 projectBalance = balance.mul(_projectShares).div(_totalShares);

        _feeProjectAddress.transfer(projectBalance);
        _feeKitAddress.transfer(kitBalance);
    }

    
    /**
     * @dev 
     */
    function releaseToken(IERC20 token) public {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "FeeDistributor: no balance to distribute");

        uint256 kitBalance = balance.mul(_kitShares).div(_totalShares);
        uint256 projectBalance = balance.mul(_projectShares).div(_totalShares);

        token.safeTransfer(_feeProjectAddress, projectBalance);
        token.safeTransfer(_feeKitAddress, kitBalance);
    }

     /**
     * @dev 
     */
    function releaseMultipleTokens(IERC20[] memory tokens) public {

        for (uint i=0; i< tokens.length; i++) {
           uint256 balance = tokens[i].balanceOf(address(this));
           if(balance > 0){
              require(balance > 0, "FeeDistributor: no balance to distribute");
              uint256 kitBalance = balance.mul(_kitShares).div(_totalShares);
              uint256 projectBalance = balance.mul(_projectShares).div(_totalShares);
              tokens[i].safeTransfer(_feeProjectAddress, projectBalance);
              tokens[i].safeTransfer(_feeKitAddress, kitBalance);
           }
        }
    }

}

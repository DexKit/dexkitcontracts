// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
/**
 * @title AirdropTrader
 * @dev Used to airdrop to traders
 */
contract AirdropTraders is Ownable {
    using SafeMath  for uint256;
    using SafeERC20 for IERC20;
    struct AirdropCampaign{
       uint256 amount;
       uint256 minHolding;
       bool active;
    }
    mapping (address => bool) private _traders;
    mapping (address => mapping(address => bool)) private _tokenTraders;
    mapping (address => AirdropCampaign) private _campaign;


    /**
     * @dev Returns trader on airdropped list
     */
    function isTrader(address sender) public view returns (bool) {
        return _traders[sender];
    }
    /**
     * @dev Returns trader that received airdropped
     */
    function isTokenTrader(address tokenAddress, address sender) public view returns (bool) {
        return _tokenTraders[tokenAddress][sender];
    }


    /**
     * @dev 
     */
    function claimAirdrop(address tokenAddress) public {
        require(_traders[msg.sender], "AirdropTraders: trader not on list");
        require(!_tokenTraders[tokenAddress][msg.sender], "AirdropTraders: already airdroped");
        require(IERC20(tokenAddress).balanceOf(msg.sender) >= _campaign[tokenAddress].minHolding, "AirdropTraders: not meet minimal holding");
        require(_campaign[tokenAddress].active, "AirdropTraders: campaign is not active");
        _tokenTraders[tokenAddress][msg.sender] = true;
        IERC20(tokenAddress).safeTransfer(msg.sender, _campaign[tokenAddress].amount);
        emit Claimed(msg.sender, _campaign[tokenAddress].amount, tokenAddress);
    }

    /**
     * @dev Add traders to list
     */
    function addTraders(address[] memory traders) public onlyOwner {
        for (uint i=0; i< traders.length; i++) {
           if(!_traders[traders[i]]){
             _traders[traders[i]] = true;
             emit AddedTrader(traders[i]);
           }
        }
    }

    /**
     * @dev Remove traders from list
     */
    function removeTraders(address[] memory traders) public onlyOwner {
        for (uint i=0; i< traders.length; i++) {
           if(_traders[traders[i]]){
             _traders[traders[i]] = false;
             emit RemovedTrader(traders[i]);
           }
        }
    }

    /**
     * @dev set Campaign
     */
    function setCampaignTraders(address tokenAddress, uint256 value, uint256 minHolding) public onlyOwner {
        _campaign[tokenAddress].amount = value;
        _campaign[tokenAddress].minHolding = minHolding;
    }

    /**
     * @dev set Active Campaign
     */
    function setCampaignStatus(address tokenAddress, bool status) public onlyOwner {
        _campaign[tokenAddress].active = status;
        emit CaimpaignActivated(status);
    }

     /**
     * @dev Owner can withdraw at any time the tokens related to airdrop
     */
    function releaseToken(IERC20 token) public onlyOwner{
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "AirdropTraders: no balance to distribute");

        token.safeTransfer(owner(), balance);
    }

    event AddedTrader(address indexed trader);
    event RemovedTrader(address indexed trader);
    event Claimed(address indexed trader, uint256 amount, address indexed tokenCampaign);
    event CaimpaignActivated(bool active);
}

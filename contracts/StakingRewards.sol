// contracts/DexKit.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "./DexKit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract StakingRewards is Ownable {

    using SafeMath for uint256;

    DexKit _token;

    struct StakingData{
        uint256 snapshot;
        uint256 totalEthToClaim;
        uint256 myClaim;
        uint256 totalClaimed;
         
    }

    mapping (uint256 => mapping (address => uint256)) private _claims;

    mapping (uint256 => uint256) private _totalSupplyClaimed;

    mapping (uint256 => uint256) private _totalEthToClaim;

    event Claimed(address indexed from, uint256 snapshotId, uint256 value);

    event Withdrawed(address indexed from, uint256 snapshotId, uint256 value);

    constructor(DexKit token ) public {
        _token = token;
    }
    /**
     * @dev When receive ETH it will add to current snapshot ID fund
     */
    receive() external payable {
        uint256 currentSnapshotId = _token.currentSnapshotId();
        _totalEthToClaim[currentSnapshotId] = _totalEthToClaim[currentSnapshotId].add(msg.value);
    }
    /**
     *
     * @dev user to claim needs to have a positive net balance between two consecutive snaphots
     */
    function claimRewards() public {
        uint256 currentSnapshotId = _token.currentSnapshotId();
        require(currentSnapshotId > 2, "Snapshot must be higher than 2");
        uint256 previousSnapshot = currentSnapshotId.sub(1);
        uint256 atualBalance = _token.balanceOfAt(msg.sender, currentSnapshotId); 
        require(atualBalance.sub(_token.balanceOfAt(msg.sender, previousSnapshot)) > 0, "your net balance needs to be positive between snapshots");
        require(_claims[currentSnapshotId][msg.sender] == 0, "already claimed");
        _claims[currentSnapshotId][msg.sender] = atualBalance;
        _totalSupplyClaimed[currentSnapshotId] = _totalSupplyClaimed[currentSnapshotId].add(atualBalance);
        emit Claimed(msg.sender, currentSnapshotId, atualBalance);
    }

    function withdrawRewards(uint256 snapshotId) public {
        uint256 currentSnapshotId = _token.currentSnapshotId();
        require(snapshotId > 1, "Snapshot must be higher than 1");
        require(snapshotId < currentSnapshotId, "can not withdraw at current snaphost");
        // We can safely assume if user has zero balance has already withdraw for this snapshotID
        require(_claims[snapshotId][msg.sender] != 0, "already withdrawed");
        uint256 shareToClaim = _claims[snapshotId][msg.sender];
        uint256 totalShares = _totalSupplyClaimed[snapshotId];
        _claims[snapshotId][msg.sender] = 0;
        uint256 totalETHAmount = _totalEthToClaim[snapshotId];
        uint256 rewardToClaim = totalETHAmount.mul(shareToClaim).div(totalShares);
        payable(msg.sender).transfer(rewardToClaim);
        emit Withdrawed(msg.sender, snapshotId, rewardToClaim);
    }
    /**
    * Withdraw multiple rewards at once
    *
     */
    function withdrawRewardsBulk(uint256 startSnapshotId, uint256 endSnapshotId) public {
        uint256 currentSnapshotId = _token.currentSnapshotId();
        require(startSnapshotId > 1, "Snapshot must be higher than 1");
        require(endSnapshotId > startSnapshotId, "end snapshot id must be higher than endSnaphotID");
        require(endSnapshotId < currentSnapshotId, "can not withdraw at current snaphost");
       
        for(uint index = startSnapshotId; index <= endSnapshotId; index++){
            if(_claims[index][msg.sender] > 0){
                uint256 shareToClaim = _claims[index][msg.sender];
                uint256 totalShares = _totalSupplyClaimed[index];
                _claims[index][msg.sender] = 0;
                uint256 totalETHAmount = _totalEthToClaim[index];
                uint256 rewardToClaim = totalETHAmount.mul(shareToClaim).div(totalShares);
                payable(msg.sender).transfer(rewardToClaim);
                emit Withdrawed(msg.sender, index, rewardToClaim);
            }
        }
    }


    function currentEthRewards() public view returns(uint256){
           uint256 currentSnapshotId = _token.currentSnapshotId();
           return _totalEthToClaim[currentSnapshotId];
    }

    function currentClaimedSupply() public view returns(uint256){
           uint256 currentSnapshotId = _token.currentSnapshotId();
           return _totalSupplyClaimed[currentSnapshotId];
    }

    function ethRewardsAt(uint256 index) public view returns(uint256){
           return _totalEthToClaim[index];
    }

    function claimedSupplyAt(uint256 index) public view returns(uint256){
           return _totalSupplyClaimed[index];
    }
    /**
    * @dev Return all Staking data for Dashboard platform
     */
    function stakingDataPerUser(uint256 startSnapshotId, uint256 endSnapshotId) public returns(StakingData[] memory stakes){
          uint256 currentSnapshotId = _token.currentSnapshotId();
          require(startSnapshotId > 1, "Snapshot must be higher than 1");
          require(endSnapshotId > startSnapshotId, "end snapshot id must be higher than endSnapshotID");
          require(endSnapshotId <= currentSnapshotId, "higher than current snapshot id");
          uint256 total = endSnapshotId.sub(startSnapshotId);
          stakes = new StakingData[](total);
          for(uint index = 0; index < total; index++){
               uint256 currentSnapshot = index.add(startSnapshotId);
               stakes[index].snapshot = currentSnapshot;
               stakes[index].totalEthToClaim = ethRewardsAt(currentSnapshot);
               stakes[index].myClaim = _claims[currentSnapshot][msg.sender];
               stakes[index].totalClaimed = claimedSupplyAt(currentSnapshotId);
           }
    }
    

}

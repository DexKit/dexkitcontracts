// contracts/BitBoyToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;
import "./BITTOKEN.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract StakingTokenRewards is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for BITTOKEN;

    BITTOKEN _token;

    struct StakingData{
        uint256 snapshot;
        uint256 totalTokenToClaim;
        uint256 myClaim;
        uint256 totalClaimed;
         
    }

    mapping (uint256 => mapping (address => uint256)) private _claims;

    mapping (uint256 => uint256) private _totalSupplyClaimed;

    mapping (uint256 => uint256) private _totalTokenToClaim;

    event Claimed(address indexed from, uint256 snapshotId, uint256 value);

    event Withdrawed(address indexed from, uint256 snapshotId, uint256 value);

    constructor(BITTOKEN token ) public {
        _token = token;
    }

    /**
    * @dev add Token rewards
     */
    function addTokenRewards(uint256 amount) public {
        require(amount > 0, "Amount Higher than zero");
        _token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 currentSnapshotId = _token.currentSnapshotId();
        _totalTokenToClaim[currentSnapshotId] = _totalTokenToClaim[currentSnapshotId].add(amount);
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
        uint256 totalTokenAmount = _totalTokenToClaim[snapshotId];
        uint256 rewardToClaim = totalTokenAmount.mul(shareToClaim).div(totalShares);
        _token.safeTransfer(msg.sender, rewardToClaim);
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
         // We can safely assume if user has zero balance has already withdraw for this snapshotID
            require(_claims[index][msg.sender] != 0, "already withdrawed");
            uint256 shareToClaim = _claims[index][msg.sender];
            uint256 totalShares = _totalSupplyClaimed[index];
            _claims[index][msg.sender] = 0;
            uint256 totalTokenAmount = _totalTokenToClaim[index];
            uint256 rewardToClaim = totalTokenAmount.mul(shareToClaim).div(totalShares);
            _token.safeTransfer(msg.sender, rewardToClaim);
            emit Withdrawed(msg.sender, index, rewardToClaim);
        }
    }


    function currentTokenRewards() public view returns(uint256){
           uint256 currentSnapshotId = _token.currentSnapshotId();
           return _totalTokenToClaim[currentSnapshotId];
    }

    function currentClaimedSupply() public view returns(uint256){
           uint256 currentSnapshotId = _token.currentSnapshotId();
           return _totalSupplyClaimed[currentSnapshotId];
    }

    function tokenRewardsAt(uint256 index) public view returns(uint256){
           return _totalTokenToClaim[index];
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
               stakes[index].totalTokenToClaim = tokenRewardsAt(currentSnapshot);
               stakes[index].myClaim = _claims[currentSnapshot][msg.sender];
               stakes[index].totalClaimed = claimedSupplyAt(currentSnapshotId);
           }
    }
    

}

// contracts/DexKit.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
/**
* DexKit smart contract with snapshot features.
* Snapshot it will be used for Governance
*
* */
contract DexKit is  ERC20Snapshot {

    using SafeMath for uint256;
     // timestamp for next snapshot
    uint256 private _snapshotTimestamp;

    uint256 private _currentSnapshotId;


    constructor() public ERC20("DexKit", "KIT"){
        _snapshotTimestamp = block.timestamp;
        // Mint all initial tokens to Deployer
        _mint(_msgSender(), 10000000 *10**18);
     
    }


    /**
    * @dev Do snapshot each 15 days if triggered. Snapshots are used for governance and rewards distribution
    */
    function doSnapshot() public returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _snapshotTimestamp + 15 days, "Not passed 15 days yet");
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
}
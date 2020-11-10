// contracts/BITTOKEN.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract BITTOKEN is ERC20Burnable, ERC20Snapshot {

    using SafeMath for uint256;
     // timestamp for next snapshot
    uint256 private _snapshotTimestamp;

    uint256 private _currentSnapshotId;

    constructor() public ERC20("BITTOKEN", "BITT") {
        _snapshotTimestamp = block.timestamp;
        // Contract Deployer
        _mint(0xf57e2D18513869b375Ce2a86CB7c325aa716f294, 42000000*10**18);
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
}
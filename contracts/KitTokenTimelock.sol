// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @dev A kit token holder contract that will allow a beneficiary to extract the
 * tokens after at least one month. This contract will be deployed for each partner, that need to deploy
 * their own instance and needs to commit at least to lock by one month
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract KitTokenTimelock {
    using SafeERC20 for IERC20;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    constructor (address beneficiary) public {
        _beneficiary = beneficiary;
        _releaseTime = block.timestamp + 30 days;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    /**
     * @dev Users have one day after release time to withdraw tokens, if not anyone can extend the period by another 30 days
     */
    function extendReleaseTime() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _releaseTime + 1 days , "KitTokenTimelock: not passed one day to user be able to withdraw");

        _releaseTime = _releaseTime + 30 days;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release(IERC20 token) public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token.safeTransfer(_beneficiary, amount);
    }
}

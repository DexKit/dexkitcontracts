// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


import "./KitTokenTimelock.sol";

/**
 * @dev A KitToken Timelock Factory to keep tracking of all affiliated contracts
 */
contract KitTokenTimelockFactory {
 
    mapping(address => KitTokenTimelock) public kitTokenTimelocks;

    event TimelockDeployed(address indexed from, address indexed beneficiary, uint256 indexed timestamp);

    ///// permissioned functions

    // deploy a kit Token Timelock to the register
    function deploy(address beneficiary) public {
        KitTokenTimelock timelock = kitTokenTimelocks[beneficiary];
        require(address(timelock) == address(0), 'KitTokenTimelockFactory::deploy: already deployed');

        kitTokenTimelocks[beneficiary] = new KitTokenTimelock(beneficiary);
        emit TimelockDeployed(msg.sender, beneficiary, block.timestamp);
    }

}

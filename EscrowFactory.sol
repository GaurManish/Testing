// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./Escrow.sol";


contract EscrowFactory {
    address[] public deployedEscrows;

    /*
        user is the sender of request i.e. msg.sender
    */

    event EscrowCreated(address indexed _escrowAddress, address indexed _user, address indexed _verifier,  address _arbiter, uint _amount);

    function createEscrow(address _verifier, address _arbiter, address _usdtAddress) external returns (address) {
        Escrow newEscrow = new Escrow(msg.sender, _verifier, _arbiter, _usdtAddress);
        deployedEscrows.push(address(newEscrow));
        
        emit EscrowCreated(address(newEscrow), msg.sender, _verifier,  _arbiter, 0);

        return address(newEscrow);
    }

    function getDeployedEscrows() external view returns (address[] memory) {
        return deployedEscrows;
    }
}
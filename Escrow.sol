// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Escrow {

    address public verifier;                            // Verifier provides service (selling service)(SELLER)
    address public user;                                // User requests for verification (buying service)(BUYER)
    address public arbiter;
    uint public amount;
    address public usdtAddress;                         // USDT contract address
    bool public fundsDeposited;

    enum State {Created, Funded, Completed, Refunded, Cancelled }
    State public state;

    event FundsDeposited(address indexed _depositer, uint _amount);
    event FundsReleased(address indexed _recipient, uint _amount);
    event EscrowCompleted();
    event EscrowRefunded();
    event EscrowCancelled();
    modifier onlyVerifier() {
        require(msg.sender == verifier, "Only the verifier can call this function");
        _;
    }

    modifier onlyUser() {
        require(msg.sender == user, "Only the user can call this function");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only the arbiter can call this function");
        _;
    }

    modifier inState(State _state) {
        require(state == _state, "Invalid state");
        _;
    }

    // constructor(address _verifier, address _user, address _arbiter, address _usdtAddress) {
    constructor(address _user, address _verifier, address _arbiter, address _usdtAddress) {
        verifier = _verifier;                                  // Verifier provides service (selling service)(SELLER)
        user = _user;                                          // User requests for verification (buying service)(BUYER)
        arbiter = _arbiter;
        usdtAddress = _usdtAddress;
        state = State.Created;
    }

    // Function to deposit USDT into the contract    --------       Called by USER when sending request
    function deposit(uint _amount) external {
        require(_amount > 0, "Deposit amount must be greater than 0");

        // Transfer USDT from the sender to this contract
        IERC20 usdtToken = IERC20(usdtAddress);
        require(usdtToken.transferFrom(msg.sender, address(this), _amount), "USDT transfer failed");

        amount = _amount;
        fundsDeposited = true;
        state = State.Funded;
        emit FundsDeposited(msg.sender, _amount);
    }

    // Function to release funds to the verifier
    function release() external onlyVerifier inState(State.Funded) {
        state = State.Completed;
        emit FundsReleased(verifier, amount);
        IERC20(usdtAddress).transfer(verifier, amount);
        emit EscrowCompleted();
    }

    // Function to refund funds to the user
    function refund() external onlyUser inState(State.Funded) {
        state = State.Refunded;
        emit FundsReleased(user, amount);
        IERC20(usdtAddress).transfer(user, amount);
        emit EscrowRefunded();
    }

    // Function to cancel the escrow by the arbiter
    function cancel() external onlyArbiter inState(State.Created) {
        state = State.Cancelled;
        emit EscrowCancelled();
        IERC20(usdtAddress).transfer(arbiter, amount);
    }

    // Function to withdraw funds after completion
    function withdraw() external onlyUser inState(State.Completed) {
        state = State.Completed;
        IERC20(usdtAddress).transfer(user, amount);
    }
    
}
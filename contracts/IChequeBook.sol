// SPDX-License-Identifier: BSD-3-Clause
pragma solidity =0.7.6;

// 

interface IChequeBook {
    // pay without hard deposit
    function pay(address _recipient, uint256 _amount) external;
    // pay with hard deposit
    function payHardDeposit(address _recipient, uint256 _amount) external;
    // hard deposit
    function deposit(uint256 _amount) external;
    // cashout
    function cashout(address _recipient, uint256 _amount) external; 
}
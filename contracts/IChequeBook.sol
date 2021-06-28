// SPDX-License-Identifier: BSD-3-Clause
pragma solidity =0.7.6;

// 

interface IChequeBook {
    // pay without hard deposit
    function pay(address beneficiary, uint256 amount) external;
    // pay with hard deposit
    function payHardDeposit(address beneficiary, uint256 amount) external;
    // hard deposit
    function deposit(uint256 amount) external;
    // cashout
    function cashout(address recipient, uint256 amount) external; 
}
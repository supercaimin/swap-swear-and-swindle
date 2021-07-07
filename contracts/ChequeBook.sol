// SPDX-License-Identifier: BSD-3-Clause
pragma solidity =0.7.6;
pragma abicoder v2;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IChequeBook.sol";

contract ChequeBook is IChequeBook {
    using SafeMath for uint256;

    event HardDepositAmountChanged(address indexed beneficiary, uint256 amount);
    event Cashouted(address indexed beneficiary, address recipient, uint256 amount);

    /* The token against which this chequebook writes cheques */
    ERC20 public token;

    mapping (address => uint256) public hardDepositBalances;
    mapping (address => uint256) public beneficiaryBalances;
    /* associates every beneficiary with how much has been paid out to them */
    mapping (address => uint256) public paidOut;
    /* total amount paid out */
    uint256 public totalPaidOut;
    /* sum of all hard deposits */
    uint256 public totalHardDeposit;
    uint256 public totalBeneficiary;
    /* issuer of the contract, set at construction */
    address public issuer;

    function init(
        address _issuer, 
        address _token
    ) 
        public 
    {
        require(_issuer != address(0), "invalid issuer");
        require(issuer == address(0), "already initialized");
        issuer = _issuer;
        token = ERC20(_token);
    }

    /// @return the balance of the chequebook
    function balance() public view returns(uint256) {
        return token.balanceOf(address(this));
    }
    /// @return the part of the balance that is not covered by hard deposits
    function liquidBalance() public view returns(uint256) {
        return balance().sub(totalHardDeposit);
    }

    function payHardDeposit(
        address _recipient, 
        uint256 _amount
    ) 
        override 
        external 
    {
        
        _decreaseHardDeposit(msg.sender, _amount);

        _increaseBeneficiary(_recipient, _amount);

        emit HardDepositAmountChanged(_recipient, beneficiaryBalances[_recipient]);
    }

    function cashout(
        address _recipient, 
        uint256 _amount
    ) 
        override
        external
    {
    
        _decreaseBeneficiary(msg.sender, _amount);

        paidOut[msg.sender] = paidOut[msg.sender].add(_amount);
        totalPaidOut = totalPaidOut.add(_amount);

        require(token.increaseAllowance(address(this), _amount), "increase allowance failed");
        require(token.transferFrom(address(this), _recipient, _amount), "cashout transfer failed");
    
        emit Cashouted(msg.sender, _recipient,  _amount);
    }
    
    function pay(
        address _recipient,
        uint256 _amount
    ) 
        override external 
    {
        require(token.transferFrom(msg.sender, address(this), _amount), "transfer failed");
        _increaseBeneficiary(_recipient, _amount);
    }

    function deposit(
        uint256 _amount
    ) 
        override
        external
    {
        require(token.transferFrom(msg.sender, address(this), _amount), "transfer failed");
        _increaseHardDeposit(msg.sender, _amount);
    }

    function _increaseHardDeposit(
        address _owner, 
        uint256 _amount
    ) 
        internal 
    {
        require(totalHardDeposit.add(_amount) <= balance(), "amount exceeds global balance");
        hardDepositBalances[_owner] = hardDepositBalances[_owner].add(_amount);
        totalHardDeposit = totalHardDeposit.add(_amount);
    }

    function _decreaseHardDeposit(
        address _owner, 
        uint256 _amount
    )
        internal
    {
        require(hardDepositBalances[_owner] >= _amount, "amount exceeds owner balance");

        require(totalHardDeposit >= _amount, "amount exceeds total hard deposit");
        
        hardDepositBalances[_owner] = hardDepositBalances[_owner].sub(_amount);
        totalHardDeposit = totalHardDeposit.sub(_amount);
    }

    function _increaseBeneficiary(
        address _owner, 
        uint256 _amount
    ) 
        internal 
    {
        require(totalBeneficiary.add(_amount) <= balance(), "amount exceeds global balance");

        beneficiaryBalances[_owner] = beneficiaryBalances[_owner].add(_amount);
        totalBeneficiary = totalBeneficiary.add(_amount);
    }

    function _decreaseBeneficiary(
        address _owner, 
        uint256 _amount
        ) 
        internal 
    {

        require(totalBeneficiary >= _amount, "amount exceeds total beneficiary");

        beneficiaryBalances[_owner] = beneficiaryBalances[_owner].sub(_amount);
        totalBeneficiary = totalBeneficiary.sub(_amount);
    }

}

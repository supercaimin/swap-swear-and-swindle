// SPDX-License-Identifier: BSD-3-Clause
pragma solidity =0.7.6;
pragma abicoder v2;
import "./openzeppelin/contracts/math/SafeMath.sol";
import "./openzeppelin/contracts/math/Math.sol";
import "./openzeppelin/contracts/token/ERC20/ERC20.sol";
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

    function init(address _issuer, address _token) public {
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

    function payHardDeposit(address recipient, uint256 amount) override external {
        
        _decreaseHardDeposit(msg.sender, amount);

        _increaseBeneficiary(recipient, amount);

        emit HardDepositAmountChanged(recipient, beneficiaryBalances[recipient]);
    }

    function cashout(address recipient, uint256 amount) override external {
    
        _decreaseBeneficiary(msg.sender, amount);

        paidOut[msg.sender] = paidOut[msg.sender].add(amount);
        totalPaidOut = totalPaidOut.add(amount);

        require(token.increaseAllowance(address(this), amount), "increase allowance failed");
        require(token.transferFrom(address(this), recipient, amount), "cashout transfer failed");
    
        emit Cashouted(msg.sender, recipient,  amount);
    }
    
    function pay(address recipient, uint256 amount) override external {
        require(token.transferFrom(msg.sender, address(this), amount), "transfer failed");
        _increaseBeneficiary(recipient, amount);
    }

    function deposit(uint256 amount) override external {
        require(token.transferFrom(msg.sender, address(this), amount), "transfer failed");
        _increaseHardDeposit(msg.sender, amount);
    }

    function _increaseHardDeposit(address owner, uint256 amount) internal {
        require(totalHardDeposit.add(amount) <= balance(), "amount exceeds global balance");
        hardDepositBalances[owner] = hardDepositBalances[owner].add(amount);
        totalHardDeposit = totalHardDeposit.add(amount);
    }

    function _decreaseHardDeposit(address owner, uint256 amount) internal {
        require(hardDepositBalances[owner] >= amount, "amount exceeds owner balance");

        require(totalHardDeposit >= amount, "amount exceeds total hard deposit");
        
        hardDepositBalances[owner] = hardDepositBalances[owner].sub(amount);
        totalHardDeposit = totalHardDeposit.sub(amount);
    }

    function _increaseBeneficiary(address owner, uint256 amount) internal {
        require(totalBeneficiary.add(amount) <= balance(), "amount exceeds global balance");

        beneficiaryBalances[owner] = beneficiaryBalances[owner].add(amount);
        totalBeneficiary = totalBeneficiary.add(amount);
    }

    function _decreaseBeneficiary(address owner, uint256 amount) internal {

        require(totalBeneficiary >= amount, "amount exceeds total beneficiary");

        beneficiaryBalances[owner] = beneficiaryBalances[owner].sub(amount);
        totalBeneficiary = totalBeneficiary.sub(amount);
    }

}

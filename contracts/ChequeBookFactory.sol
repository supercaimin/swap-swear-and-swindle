// SPDX-License-Identifier: BSD-3-Clause
pragma solidity =0.7.6;
pragma abicoder v2;
import "./ChequeBook.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/**
@title Factory contract for ChequeBook
@author The Swarm Authors
@notice This contract deploys ChequeBook contracts
*/
contract ChequeBookFactory {

  /* event fired on every new ChequeBook deployment */
  event ChequeBookDeployed(address contractAddress);

  /* store chequebook contract  were deployed by this factory */
  address public deployedContractAddress;

  /* address of the ERC20-token, to be used by the to-be-deployed chequebooks */
  address public ERC20Address;
  /* address of the code contract from which all chequebooks are cloned */
  address public master;

  constructor(address _ERC20Address) {
    ERC20Address = _ERC20Address;
    ChequeBook _master = new ChequeBook();
    // set the issuer of the master contract to prevent misuse
    _master.init(address(1), address(0));
    master = address(_master);
  }
  /**
  @notice creates a clone of the master ChequeBook contract
  @param issuer the issuer of cheques for the new chequebook
  @param salt salt to include in create2 to enable the same address to deploy multiple chequebooks
  */
  function deployChequeBook(address issuer, bytes32 salt) public returns (address) {    
    address contractAddress = Clones.cloneDeterministic(master, keccak256(abi.encode(msg.sender, salt)));
    ChequeBook(contractAddress).init(issuer, ERC20Address);
    deployedContractAddress = contractAddress;
    emit ChequeBookDeployed(contractAddress);
    return contractAddress;
  }
}
/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

///@title Ants-Review
///@author Nazzareno Massari @naszam
///@notice ANTS Faucet
///@dev All function calls are currently implemented without side effects through TDD approach
///@dev OpenZeppelin library is used for secure contract development

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

interface AntsToken {
  function transfer(address recipient, uint amount) external returns (bool);
  function balanceOf(address account) external view returns (uint);
}

contract AntsFaucet is Ownable, AccessControl, Pausable {

  /// @dev Pauser Role
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /// @dev Token
  AntsToken internal immutable ants;

  /// @dev Events
  event Withdrawal(address account);
  event Deposit(address indexed from, uint amount);


  constructor(address ants_) public {
    _setupRole(DEFAULT_ADMIN_ROLE, owner());
    _setupRole(PAUSER_ROLE, owner());

    ants = AntsToken(ants_);
  }

  /// @dev Functions

  /// @notice Accept any incoming amount
  receive() external payable {
    emit Deposit (msg.sender, msg.value);
  }

  /// @notice Give 10 ANTS to anyone who asks
  /// @dev Checks if balance is more or equal to 10 ANTS
  /// @return True If 10 ANTS are successfully withdrawn
  function withdraw() external returns (bool) {
      require(ants.balanceOf(address(this)) >= 10, "Insufficient balance of ANTS in the faucet");

      ants.transfer(msg.sender, 10 ether);

      emit Withdrawal(msg.sender);
      return true;
  }

  /// @notice Pause all the functions
  /// @dev the caller must have the 'PAUSER_ROLE'
  function pause() external {
    require(hasRole(PAUSER_ROLE, msg.sender), "AntsFaucet: must have pauser role to pause");
    ants.transfer(owner(), ants.balanceOf(address(this)));
    _pause();
  }

  /// @notice Unpause all the functions
  /// @dev the caller must have the 'PAUSER_ROLE'
  function unpause() external {
        require(hasRole(PAUSER_ROLE, msg.sender), "AntsFaucet: must have pauser role to unpause");
        _unpause();
  }

}

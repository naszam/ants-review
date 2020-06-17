/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.10;

///@title Ants-Review
///@author Nazzareno Massari
///@notice Ant Faucet
///@dev All function calls are currently implemented without side effects through TDD approach
///@dev OpenZeppelin library is used for secure contract development

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Pausable.sol";

interface AntToken {
  function transfer(address reciptient, uint amount) external returns (bool);
  function balanceOf(address account) external view returns (uint);
}

contract AntFaucet is Ownable, AccessControl, Pausable {

  /// @dev Pauser Role
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /// @dev Token
  AntToken internal ant;

  /// @dev Events
  event Withdrawal(address indexed to);
  event Deposit(address indexed from, uint amount);


  constructor(address ant_) public {
    _setupRole(DEFAULT_ADMIN_ROLE, owner());
    _setupRole(PAUSER_ROLE, owner());

    ant = AntToken(ant_);
  }

  /// @dev Modifier
  modifier onlyAdmin() {
      require(isAdmin(msg.sender), "Caller is not an admin");
      _;
    }

  /// @dev Functions

  /// @notice Accept any incoming amount
  receive() external payable {
    emit Deposit (msg.sender, msg.value);
  }


  /// @notice Check if account is an Admin
  /// @dev Used in onlyAdmin() modifier
  /// @param account Address to check
  /// @return True If the account is an Admin
  function isAdmin(address account) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }

  /// @notice Give 1 Ant to anyone who asks
  /// @dev Checks if balance is more or equal to 1 Ant
  /// @return True If 1 Ant is successfully withdrawn
  function withdraw() external {
      require(ant.balanceOf(address(this)) >= 1 ether, "Insufficient balance in faucet for withdrawal 1 Ant");

      ant.transfer(msg.sender, 1 ether);
      emit Withdrawal(msg.sender);
  }

  /// @notice Pause all the functions
  /// @dev the caller must have the 'PAUSER_ROLE'
  function pause() external {
    ant.transfer(owner(), ant.balanceOf(address(this)));
    require(hasRole(PAUSER_ROLE, msg.sender), "BadgeFactory: must have pauser role to pause");
    _pause();
  }

  /// @notice Unpause all the functions
  /// @dev the caller must have the 'PAUSER_ROLE'
  function unpause() external {
        require(hasRole(PAUSER_ROLE, msg.sender), "BadgeFactory: must have pauser role to unpause");
        _unpause();
  }

}

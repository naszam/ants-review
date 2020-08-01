/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

///@title Ants-Review
///@author Nazzareno Massari @naszam
///@notice Ants-Review ERC20 Token
///@dev All function calls are currently implemented without side effects through TDD approach
///@dev OpenZeppelin library is used for secure contract development

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";



contract ANTS is Ownable, AccessControl, ERC20Burnable, ERC20Pausable {

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  constructor() public ERC20("Ants-Review", "ANTS"){
    _setupRole(DEFAULT_ADMIN_ROLE, owner());

    _setupRole(MINTER_ROLE, owner());
    _setupRole(PAUSER_ROLE, owner());

  }

  /// @dev Modifiers
  modifier onlyAdmin() {
     require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
     _;
  }

  modifier onlyMinter() {
      require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
      _;
  }

  /// @notice Mint new WFIL
  /// @dev Access restricted only for Minters
  /// @param to Address of the recipient
  /// @param amount Amount of WFIL issued
  /// @return True if WFIL is successfully minted
  function mint(address to, uint256 amount) external onlyMinter returns (bool) {
      _mint(to, amount);
      return true;
  }

  /// @notice Add a new Minter
  /// @dev Access restricted only for Admins
  /// @param account Address of the new Minter
  /// @return True if the account address is added as Minter
  function addMinter(address account) external onlyAdmin returns (bool) {
    require(!hasRole(MINTER_ROLE, account), "Account is already a minter");
    grantRole(MINTER_ROLE, account);
    return true;
  }

  /// @notice Remove a Minter
  /// @dev Access restricted only for Admins
  /// @param account Address of the Minter
  /// @return True if the account address is removed as Minter
  function removeMinter(address account) external onlyAdmin returns (bool) {
    require(hasRole(MINTER_ROLE, account), "Account is not a minter");
    revokeRole(MINTER_ROLE, account);
    return true;
  }

  /// @notice Pause all the functions
  /// @dev the caller must have the 'PAUSER_ROLE'
  function pause() external {
      require(hasRole(PAUSER_ROLE, msg.sender), "ANTS: must have pauser role to pause");
      _pause();
  }

  /// @notice Unpause all the functions
  /// @dev the caller must have the 'PAUSER_ROLE'
  function unpause() external {
      require(hasRole(PAUSER_ROLE, msg.sender), "ANTS: must have pauser role to unpause");
      _unpause();
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Pausable) {
      super._beforeTokenTransfer(from, to, amount);
  }

}

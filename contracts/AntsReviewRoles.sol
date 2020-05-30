/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.8;

///@title AntsReview
///@author Nazzareno Massari
///@notice AntsReviewRoles Access Management for Issuer and Peer-Reviewer
///@dev All function calls are currently implemented without side effecs through TDD approach
///@dev OpenZeppelin library is used for secure contract development

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract AntsReviewRoles is Ownable, AccessControl, Pausable {

  /// Roles
  bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
  bytes32 public constant PEER_REVIEWER_ROLE = keccak256("PEER_REVIEWER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");


  constructor() public {
          _setupRole(DEFAULT_ADMIN_ROLE, owner());
          _setupRole(PAUSER_ROLE, owner());
  }

    /// Modifiers
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Caller is not an admin");
        _;
      }

    modifier onlyIssuer() {
        require(isIssuer(msg.sender), "Caller is not an issuer");
        _;
    }

    modifier onlyPeerReviewer() {
        require(isPeerReviewer(msg.sender), "Caller is not a peer-reviewer");
        _;
    }

    /// Functions

    function isAdmin(address account) public view returns (bool) {
      return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isIssuer(address account ) public view returns (bool) {
      return hasRole(ISSUER_ROLE, account);
    }

    function isPeerReviewer(address account ) public view returns (bool) {
      return hasRole(PEER_REVIEWER_ROLE, account);
    }

    function addIssuer(address account) public onlyAdmin returns (bool) {
      require(!isIssuer(account), "Account is already an issuer");
      grantRole(ISSUER_ROLE, account);
      return true;
    }

    function addPeerReviewer(address account) public onlyAdmin returns (bool) {
      require(!isPeerReviewer(account), "Account is already a peer-reviewer");
      grantRole(PEER_REVIEWER_ROLE, account);
      return true;
    }

    function removeIssuer(address account) public onlyAdmin returns (bool) {
      require(isIssuer(account), "Account is not an issuer");
      revokeRole(ISSUER_ROLE, account);
      return true;
    }

    function removePeerReviewer(address account) public onlyAdmin returns (bool) {
      require(isPeerReviewer(account), "Account is not a peer-reviewer");
      revokeRole(PEER_REVIEWER_ROLE, account);
      return true;
    }

    /// @notice Pause all the functions
    /// @dev the caller must have the 'PAUSER_ROLE'
    function pause() public {
      require(hasRole(PAUSER_ROLE, msg.sender), "BadgeFactory: must have pauser role to pause");
      _pause();
    }

    /// @notice Unpause all the functions
    /// @dev the caller must have the 'PAUSER_ROLE'
    function unpause() public {
          require(hasRole(PAUSER_ROLE, msg.sender), "BadgeFactory: must have pauser role to unpause");
          _unpause();
    }
}

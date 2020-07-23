/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.11;

///@title Ants-Review
///@author Nazzareno Massari @naszam
///@notice AntsReviewRoles Access Management for Issuer and Peer-Reviewer
///@dev All function calls are currently implemented without side effects through TDD approach
///@dev OpenZeppelin library is used for secure contract development

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract AntsReviewRoles is Ownable, AccessControl, Pausable {

  /// @dev Roles
  bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
  bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");
  bytes32 public constant PEER_REVIEWER_ROLE = keccak256("PEER_REVIEWER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");


  constructor() public {
          _setupRole(DEFAULT_ADMIN_ROLE, owner());
          _setupRole(PAUSER_ROLE, owner());
  }

    /// @dev Modifiers
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Caller is not an admin");
        _;
      }

    modifier onlyIssuer() {
        require(isIssuer(msg.sender), "Caller is not an issuer");
        _;
    }

    modifier onlyApprover() {
        require(isApprover(msg.sender), "Caller is not an approver");
        _;
    }

    modifier onlyPeerReviewer() {
        require(isPeerReviewer(msg.sender), "Caller is not a peer-reviewer");
        _;
    }

    /// @dev Functions

    /// @notice Check if account is an Admin
    /// @dev Used in onlyAdmin() modifier
    /// @param account Address to check
    /// @return True If the account is an Admin
    function isAdmin(address account) public view returns (bool) {
      return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @notice Check if account is an Issuer
    /// @dev Used in onlyIssuer() modifier
    /// @param account Address to check
    /// @return True If the account is an Issuer
    function isIssuer(address account) public view returns (bool) {
      return hasRole(ISSUER_ROLE, account);
    }

    /// @notice Check if account is an Approver
    /// @dev Used in onlyApprover() modifier
    /// @param account Address to check
    /// @return True If the account is an Approver
    function isApprover(address account) public view returns (bool) {
      return hasRole(APPROVER_ROLE, account);
    }

    /// @notice Check if account is a Peer-Reviewer
    /// @dev Used in onlyPeerReviewer() modifier
    /// @param account Address to check
    /// @return True If the account is a Peer-Reviewer
    function isPeerReviewer(address account) public view returns (bool) {
      return hasRole(PEER_REVIEWER_ROLE, account);
    }

    /// @notice Add a new Issuer
    /// @dev Access restricted only for Admins
    /// @param account Address of the new Issuer
    /// @return True if the account address is added as Issuer
    function addIssuer(address account) external onlyAdmin returns (bool) {
      require(!isIssuer(account), "Account is already an issuer");
      grantRole(ISSUER_ROLE, account);
      return true;
    }

    /// @notice Add a new Approver
    /// @dev Access restricted only for Admins
    /// @param account Address of the new Approver
    /// @return True if the account address is added as Approver
    function addApprover(address account) external onlyAdmin returns (bool) {
      require(!isApprover(account), "Account is already an approver");
      grantRole(APPROVER_ROLE, account);
      return true;
    }

    /// @notice Add a new Peer-Reviewer
    /// @dev Access restricted only for Admins
    /// @param account Address of the new Peer-Reviewer
    /// @return True if the account address is added as Peer-Reviewer
    function addPeerReviewer(address account) external onlyAdmin returns (bool) {
      require(!isPeerReviewer(account), "Account is already a peer-reviewer");
      grantRole(PEER_REVIEWER_ROLE, account);
      return true;
    }

    /// @notice Remove an Issuer
    /// @dev Access restricted only for Admins
    /// @param account Address of the Issuer
    /// @return True if the account address is removed as Issuer
    function removeIssuer(address account) external onlyAdmin returns (bool) {
      require(isIssuer(account), "Account is not an issuer");
      revokeRole(ISSUER_ROLE, account);
      return true;
    }

    /// @notice Remove an Approver
    /// @dev Access restricted only for Admins
    /// @param account Address of the Approver
    /// @return True if the account address is removed as Approver
    function removeApprover(address account) external onlyAdmin returns (bool) {
      require(isApprover(account), "Account is not an approver");
      revokeRole(APPROVER_ROLE, account);
      return true;
    }

    /// @notice Remove a Peer-Reviewer
    /// @dev Access restricted only for Admins
    /// @param account Address of the Peer-Reviewer
    /// @return True if the account address is removed as Peer-Reviewer
    function removePeerReviewer(address account) external onlyAdmin returns (bool) {
      require(isPeerReviewer(account), "Account is not a peer-reviewer");
      revokeRole(PEER_REVIEWER_ROLE, account);
      return true;
    }

    /// @notice Pause all the functions
    /// @dev the caller must have the 'PAUSER_ROLE'
    function pause() external {
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

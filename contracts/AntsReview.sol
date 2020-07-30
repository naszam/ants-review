/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title Ants-Review
/// @author Nazzareno Massari @naszam
/// @notice AntsReview to allows issuer to issue an antReview which peer-reviewers can fulfill
/// @dev All function calls are currently implemented without side effects through TDD approach
/// @dev OpenZeppelin library is used for secure contract development

/**

 █████  ███    ██ ████████ ███████       ██████  ███████ ██    ██ ██ ███████ ██     ██ 
██   ██ ████   ██    ██    ██            ██   ██ ██      ██    ██ ██ ██      ██     ██ 
███████ ██ ██  ██    ██    ███████ █████ ██████  █████   ██    ██ ██ █████   ██  █  ██ 
██   ██ ██  ██ ██    ██         ██       ██   ██ ██       ██  ██  ██ ██      ██ ███ ██ 
██   ██ ██   ████    ██    ███████       ██   ██ ███████   ████   ██ ███████  ███ ███  

**/


import "./AntsReviewRoles.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";



interface AntsToken {
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  function balanceOf(address account) external view returns (uint);
}

contract AntsReview is AntsReviewRoles {

  using SafeMath for uint256;
  using Address for address payable;
  using Counters for Counters.Counter;
  using EnumerableSet for EnumerableSet.AddressSet;


  /// @dev Enums
  enum AntReviewStatus { CREATED, PAID}

  /// @dev Token
  AntsToken internal immutable ants;

  /// @dev AntReview Counter
  Counters.Counter public antReviewIdTracker;

  /// @dev Storage
  AntReview[] public antreviews;
  mapping (uint256 => Peer_Review[]) public peer_reviews;
  mapping (uint256 => Contribution[]) public contributions;

  mapping (uint256 => EnumerableSet.AddressSet) private approvers;


  /// @dev Structs
  struct AntReview {
      address payable[] issuers;
      string paperHash;
      string requirementsHash;
      uint256 deadline;
      AntReviewStatus status;
      uint256 balance;
  }

  struct Peer_Review {
      bool accepted;
      address payable peer_reviewer;
      string reviewHash;
  }

  struct Contribution {
    address payable contributor;
    uint amount;
    bool refunded;
  }


  /// @dev Events

  event AntReviewIssued(uint antId, address payable[] issuers, string paperHash, string requirementsHash, uint64 deadline);
  event ContributionAdded(uint antId, uint contributionId, address contributor, uint amount);
  event AntReviewFulfilled(uint antId, uint reviewId, address peer_reviewer, string reviewHash);
  event ReviewUpdated(uint antId, uint reviewId, string reviewHash);
  event AntReviewAccepted(uint antId, uint reviewId, address approver, uint amount);
  event AntReviewChanged(uint antId, address issuer, address payable[] issuers, string paperHash, string requirementsHash, uint64 deadline);

  constructor(address ants_) public {
    ants = AntsToken(ants_);
  }

  /// @dev Fallback

  fallback() external {
    revert();
  }


  /// @dev Modifiers

  modifier antReviewExists(uint256 _antId){
    require(_antId <= antReviewIdTracker.current());
    _;
  }

  modifier reviewExists(uint256 _antId, uint256 _reviewId){
    require(_reviewId < peer_reviews[_antId].length);
    _;
  }

  modifier hasStatus(uint256 _antId, AntReviewStatus _desiredStatus) {
    require(antreviews[_antId].status == _desiredStatus);
    _;
  }

  modifier peerReviewNotYetAccepted(uint256 _antId, uint256 _reviewId) {
    require(peer_reviews[_antId][_reviewId].accepted == false);
    _;
  }

  modifier validateDeadline(uint256 _deadline) {
      require(_deadline > now);
      _;
  }

  modifier isBeforeDeadline(uint256 _antId) {
    require(now < antreviews[_antId].deadline);
    _;
  }

  modifier validAmount(uint256 _amount) {
    require(_amount > 0, "Insufficient amount");
    _;
  }

  modifier onlyContributor(uint _antId, uint _contributionId) {
    require(msg.sender == contributions[_antId][_contributionId].contributor, "Caller is not a Contributor");
    _;
  }

  modifier hasNotPaid(uint _antId)
  {
    require(antreviews[_antId].status != AntReviewStatus.PAID);
    _;
  }

  modifier hasNotRefunded(uint _antId, uint _contributionId)
  {
    require(!contributions[_antId][_contributionId].refunded);
    _;
  }

  modifier onlySubmitter(uint _antId, uint _reviewId)
  {
    require(msg.sender == peer_reviews[_antId][_reviewId].peer_reviewer);
    _;
  }

  modifier onlyApprover(uint _antId)
  {
    require(approvers[_antId].contains(msg.sender));
    _;
  }

  modifier hasIssuer(uint _antId, uint _issuerId)
  {
    require(antreviews[_antId].issuers[_issuerId] == msg.sender);
    _;
  }

  /// @dev Getters

  function getApprover(uint _antId) external view whenNotPaused returns (address) {
    return approvers[_antId].at(0);
  }


  /// @notice Create a new AntReview
  /// @dev Access restricted to Issuer
  /// @param _issuers The issuers of the AntReview
  /// @param _approver The approver of the AntReview
  /// @param _paperHash The IPFS Hash of the Scientific Paper
  /// @param _requirementsHash The IPFS Hash of the Peer-Review Requirements
  /// @param _deadline The unix timestamp after which fulfillments will no longer be accepted
  /// @return antId If the AntReview is successfully issued
  function issueAntReview(
      address payable[] calldata _issuers,
      address _approver,
      string calldata _paperHash,
      string calldata _requirementsHash,
      uint64 _deadline)
      external
      onlyIssuer()
      validateDeadline(_deadline)
      whenNotPaused()
      returns (bool)
  {
      uint antId = antReviewIdTracker.current();

      antreviews.push(AntReview(_issuers, _paperHash, _requirementsHash, _deadline, AntReviewStatus.CREATED, 0));

      require(_addApprover(antId, _approver));

      antReviewIdTracker.increment();

      emit AntReviewIssued(antId, _issuers, _paperHash, _requirementsHash, _deadline);

      return true;
  }

  function contribute(uint _antId, uint _amount)
    payable
    external
    antReviewExists(_antId)
    validAmount(_amount)
    whenNotPaused()
    returns (bool)
  {
    contributions[_antId].push(Contribution(msg.sender, _amount, false));
    antreviews[_antId].balance = antreviews[_antId].balance.add(_amount);

    require(msg.value == 0);
    require(ants.transferFrom(msg.sender, address(this), _amount));

    emit ContributionAdded(_antId, contributions[_antId].length.sub(1), msg.sender, _amount);

    return true;
  }

  function refund(uint _antId, uint _contributionId)
    external
    antReviewExists(_antId)
    onlyContributor(_antId, _contributionId)
    hasNotPaid(_antId)
    hasNotRefunded(_antId, _contributionId)
    whenNotPaused()
    returns (bool)
  {
    require(now > antreviews[_antId].deadline);

    Contribution storage contribution = contributions[_antId][_contributionId];

    contribution.refunded = true;
    antreviews[_antId].balance = antreviews[_antId].balance.sub(contribution.amount);

    require(ants.transferFrom(address(this), contribution.contributor, contribution.amount));

    return true;
  }


  /// @notice Submit a fulfillment for the given antReview
  /// @dev Access restricted to Peer-Reviewer
  /// @param _antId The index of the antReview to be fufilled
  /// @param _reviewHash The IPFS Hash of the peer-review
  /// @return True If the AntReview is successfully fulfilled
  function fulfillAntReview(uint256 _antId, string calldata _reviewHash)
    external
    onlyPeerReviewer()
    antReviewExists(_antId)
    hasStatus(_antId, AntReviewStatus.CREATED)
    isBeforeDeadline(_antId)
    whenNotPaused()
    returns (bool)
  {
    peer_reviews[_antId].push(Peer_Review(false, msg.sender, _reviewHash));

    emit AntReviewFulfilled(_antId, peer_reviews[_antId].length.sub(1), msg.sender, _reviewHash);
    return true;
  }

  function updateReview(uint _antId, uint _reviewId, string calldata _reviewHash)
    external
    onlySubmitter(_antId, _reviewId)
    reviewExists(_antId, _reviewId)
    hasStatus(_antId, AntReviewStatus.CREATED)
    isBeforeDeadline(_antId)
    whenNotPaused()
    returns (bool)
  {
    peer_reviews[_antId][_reviewId].reviewHash = _reviewHash;

    emit ReviewUpdated(_antId, _reviewId, _reviewHash);
    return true;
  }


  /// @notice Accept a given Peer-Review
  /// @dev Access restricted to Issuer
  /// @param _antId the index of the antReview
  /// @param _reviewId the index of the fulfillment being accepted
  /// @return True If the AntReview is successfully being accepted
  function acceptAntReview(uint _antId, uint _reviewId, uint _amount)
      external
      onlyApprover(_antId)
      reviewExists(_antId, _reviewId)
      hasStatus(_antId, AntReviewStatus.CREATED)
      peerReviewNotYetAccepted(_antId, _reviewId)
      whenNotPaused()
      returns (bool)
  {
      antreviews[_antId].status = AntReviewStatus.PAID;
      antreviews[_antId].balance = antreviews[_antId].balance.sub(_amount);

      require(ants.transferFrom(address(this), peer_reviews[_antId][_reviewId].peer_reviewer, _amount));


      emit AntReviewAccepted(_antId, _reviewId, msg.sender, _amount);
      return true;
  }

  function changeAntReview(
      uint _antId,
      uint _issuerId,
      address payable[] calldata _issuers,
      string calldata _paperHash,
      string calldata _requirementsHash,
      uint64 _deadline)
      external
      antReviewExists(_antId)
      hasIssuer(_antId, _issuerId)
      whenNotPaused()
      returns (bool)
  {
    antreviews[_antId].issuers = _issuers;
    antreviews[_antId].paperHash = _paperHash;
    antreviews[_antId].requirementsHash = _requirementsHash;
    antreviews[_antId].deadline = _deadline;

    emit AntReviewChanged(_antId, msg.sender, _issuers, _paperHash, _requirementsHash, _deadline);
    return true;
  }

  function _addApprover(uint _antId, address _account) private whenNotPaused returns (bool) {
    return approvers[_antId].add(_account);
  }

  function addApprover(uint _antId, uint _issuerId, address _account)
      external
      antReviewExists(_antId)
      hasIssuer(_antId, _issuerId)
      whenNotPaused()
      returns (bool)
  {
    require(!approvers[_antId].contains(_account), "Account is already an approver");
    require(approvers[_antId].add(_account));
    return true;
  }

  function removeApprover(uint _antId, uint _issuerId, address _account)
      external
      antReviewExists(_antId)
      hasIssuer(_antId, _issuerId)
      whenNotPaused()
      returns (bool)
  {
    require(approvers[_antId].contains(_account), "Account is not an approver");
    require(approvers[_antId].remove(_account));
    return true;
  }

}

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

///@title Ants-Review
///@author Nazzareno Massari @naszam
///@notice AntsReview to allows issuer to issue an antReview which peer-reviewers can fulfill
///@dev All function calls are currently implemented without side effects through TDD approach
///@dev OpenZeppelin library is used for secure contract development

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

interface AntsToken {
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  function balanceOf(address account) external view returns (uint);
}

contract AntsReview is AntsReviewRoles {

  using SafeMath for uint256;
  using Address for address payable;
  using Counters for Counters.Counter;

  /// @dev Enums
  enum AntReviewStatus { CREATED, ACCEPTED, PAID }

  /// @dev Token
  AntsToken internal immutable ants;

  /// @dev AntReview Counter
  Counters.Counter public antReviewIdTracker;

  /// @dev Storage
  AntReview[] public antreviews;


  /// @dev Structs
  struct AntReview {
      address payable[] issuers;
      address[] approvers;
      uint256 deadline;
      uint balance;
      string paperHash;
      string requirementsHash;
      AntReviewStatus status;
      Peer_Review[] peer_reviews;
      Contribution[] contributions;
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

  event AntReviewIssued(uint antId, address payable[] issuers, address[] approvers, string paperHash, string requirementsHash, uint64 deadline);
  event ContributionAdded(uint antId, uint contributionId, address contributor, uint amount);
  event AntReviewFulfilled(uint antId, uint reviewId, address peer_reviewer, string reviewHash);
  event ReviewUpdated(uint _antId, uint _reviewId, string _reviewHash);
  event AntReviewAccepted();

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
    require(_reviewId < antreviews[_antId].peer_reviews.length);
    _;
  }

  modifier hasStatus(uint256 _antReviewId, AntReviewStatus _desiredStatus) {
    require(antreviews[_antReviewId].status == _desiredStatus);
    _;
  }

  modifier peerReviewNotYetAccepted(uint256 _antId, uint256 _reviewId) {
    require(antreviews[_antId].peer_reviews[_reviewId].accepted == false);
    _;
  }

  modifier validateDeadline(uint256 _newDeadline) {
      require(_newDeadline > now);
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
    require(msg.sender == antreviews[_antId].contributions[_contributionId].contributor, "Caller is not a Contributor");
    _;
  }

  modifier hasNotPaid(uint _antId)
  {
    require(antreviews[_antId].status != AntReviewStatus.PAID);
    _;
  }

  modifier hasNotRefunded(uint _antId, uint _contributionId)
  {
    require(!antreviews[_antId].contributions[_contributionId].refunded);
    _;
  }

  modifier onlySubmitter(uint _antId, uint _reviewId)
  {
    require(msg.sender == antreviews[_antId].peer_reviews[_reviewId].peer_reviewer);
    _;
  }


  ///@notice Create a new AntReview
  ///@dev Access restricted to Issuer
  ///@param _issuers The array of addresses who will be the issuers of the AntReview
  ///@param _approvers The array of addresses who will be the approvers of the AntReview
  ///@param _paperHash The IPFS Hash of the Scientific Paper
  ///@param _requirementsHash The IPFS Hash of the Peer-Review Requirements
  ///@param _deadline The unix timestamp after which fulfillments will no longer be accepted
  ///@return antId If the AntReview is successfully issued
  function issueAntReview(
      address payable[] calldata _issuers,
      address [] calldata _approvers,
      string calldata _paperHash,
      string calldata _requirementsHash,
      uint64 _deadline
  )
      external
      validateDeadline(_deadline)
      onlyIssuer()
      whenNotPaused()
      returns (bool)
  {
      require(_issuers.length > 0 || _approvers.length > 0);

      uint antId = antReviewIdTracker.current();

      AntReview memory newAntReview = antreviews[antId];
      newAntReview.issuers = _issuers;
      newAntReview.approvers = _approvers;
      newAntReview.paperHash = _paperHash;
      newAntReview.requirementsHash = _requirementsHash;
      newAntReview.deadline = _deadline;
      newAntReview.status = AntReviewStatus.CREATED;

      antReviewIdTracker.increment();

      emit AntReviewIssued(antId, _issuers, _approvers, _paperHash, _requirementsHash, _deadline);

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
    antreviews[_antId].contributions.push(Contribution(msg.sender, _amount, false));
    antreviews[_antId].balance = antreviews[_antId].balance.add(_amount);

    require(msg.value == 0);
    require(ants.transferFrom(msg.sender, address(this), _amount));

    emit ContributionAdded(_antId, antreviews[_antId].contributions.length.sub(1), msg.sender, _amount);

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

    Contribution storage contribution = antreviews[_antId].contributions[_contributionId];

    contribution.refunded = true;
    antreviews[_antId].balance = antreviews[_antId].balance.sub(contribution.amount);

    require(ants.transferFrom(address(this), contribution.contributor, contribution.amount));

    return true;
  }


  ///@notice Submit a fulfillment for the given antReview
  ///@dev Access restricted to Peer-Reviewer
  ///@param _antId The index of the antReview to be fufilled
  ///@param _reviewHash The IPFS Hash of the peer-review
  ///@return True If the AntReview is successfully fulfilled
  function fulfillAntReview(uint256 _antId, string calldata _reviewHash)
    external
    onlyPeerReviewer()
    antReviewExists(_antId)
    hasStatus(_antId, AntReviewStatus.CREATED)
    isBeforeDeadline(_antId)
    whenNotPaused()
    returns (bool)
  {
    antreviews[_antId].peer_reviews.push(Peer_Review(false, msg.sender, _reviewHash));

    emit AntReviewFulfilled(_antId, antreviews[_antId].peer_reviews.length.sub(1), msg.sender, _reviewHash);
    return true;
  }

  function updateReview(uint _antId, uint _reviewId, string calldata _reviewHash)
    external
    onlySubmitter(_antId, _reviewId)
    antReviewExists(_antId)
    reviewExists(_antId, _reviewId)
    hasStatus(_antId, AntReviewStatus.CREATED)
    isBeforeDeadline(_antId)
    whenNotPaused()
    returns (bool)
  {
    antreviews[_antId].peer_reviews[_reviewId].reviewHash = _reviewHash;

    emit ReviewUpdated(_antId, _reviewId, _reviewHash);
    return true;
  }


  ///@notice Accept a given Peer-Review
  ///@dev Access restricted to Issuer
  ///@param _antId the index of the antReview
  ///@param _reviewId the index of the fulfillment being accepted
  ///@return True If the AntReview is successfully being accepted
  function acceptAntReview(uint _antId, uint _reviewId, uint _amount)
      external
      onlyApprover()
      antReviewExists(_antId)
      reviewExists(_antId, _reviewId)
      hasStatus(_antId, AntReviewStatus.CREATED)
      peerReviewNotYetAccepted(_antId, _reviewId)
      whenNotPaused()
      returns (bool)
  {
      antreviews[_antId].status = AntReviewStatus.PAID;
      antreviews[_antId].balance = antreviews[_antId].balance.sub(_amount);

      require(ants.transferFrom(address(this), antreviews[_antId].peer_reviews[_reviewId].peer_reviewer, _amount));


      emit AntReviewAccepted();
      return true;
  }

}

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.11;

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
  function transfer(address reciptient, uint amount) external returns (bool);
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
      AntReviewStatus status;
      Peer_Review[] peer_reviews;
      Contribution[] contributions;
  }

  struct Peer_Review {
      bool accepted;
      address payable peer_reviewer;
      string peer_review_hash;
  }

  struct Contribution {
    address payable contributor;
    uint amount;
    bool refunded;
  }


  /// @dev Events

  event AntReviewIssued(uint antId, address payable[] issuers, address[] approvers, string paperHash, uint64 deadline);
  event AntReviewFulfilled();
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

  modifier peerReviewExists(uint256 _antId, uint256 _reviewId){
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


  ///@notice Create a new AntReview
  ///@dev Access restricted to Issuer
  ///@param _issuers The array of addresses who will be the issuers of the AntReview
  ///@param _approvers The array of addresses who will be the approvers of the AntReview
  ///@param _paperHash The IPFS Hash of the Scientific Paper
  ///@param _deadline The unix timestamp after which fulfillments will no longer be accepted
  ///@return antId If the AntReview is successfully issued
  function issueAntReview(
      address payable[] calldata _issuers,
      address [] calldata _approvers,
      string calldata _paperHash,
      uint64 _deadline
  )
      external
      validateDeadline(_deadline)
      onlyIssuer()
      whenNotPaused()
      returns (uint)
  {
      require(_issuers.length > 0 || _approvers.length > 0);

      uint antId = antReviewIdTracker.current();

      AntReview memory newAntReview = antreviews[antId];
      newAntReview.issuers = _issuers;
      newAntReview.approvers = _approvers;
      newAntReview.paperHash = _paperHash;
      newAntReview.deadline = _deadline;
      newAntReview.status = AntReviewStatus.CREATED;

      antReviewIdTracker.increment();

      emit AntReviewIssued(antId, _issuers, _approvers, _paperHash, _deadline);

      return (antId);
  }


  ///@notice Submit a fulfillment for the given antReview
  ///@dev Access restricted to Peer-Reviewer
  ///@param _antId The index of the antReview to be fufilled
  ///@return True If the AntReview is successfully fulfilled
  function fulfillAntReview(uint256 _antId)
    external
    antReviewExists(_antId)
    onlyPeerReviewer()
    hasStatus(_antId, AntReviewStatus.CREATED)
    isBeforeDeadline(_antId)
    whenNotPaused()
    returns (bool)
  {
    emit AntReviewFulfilled();
    return true;
  }


  ///@notice Accept a given Peer-Review
  ///@dev Access restricted to Issuer
  ///@param _antId the index of the antReview
  ///@param _reviewId the index of the fulfillment being accepted
  ///@return True If the AntReview is successfully being accepted
  function acceptAntReview(uint256 _antId, uint256 _reviewId)
      external
      antReviewExists(_antId)
      peerReviewExists(_antId,_reviewId)
      onlyIssuer()
      hasStatus(_antId, AntReviewStatus.CREATED)
      peerReviewNotYetAccepted(_antId, _reviewId)
      whenNotPaused()
      returns (bool)
  {
      emit AntReviewAccepted();
      return true;
  }

}

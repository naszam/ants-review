/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.11;

///@title Ants-Review
///@author Nazzareno Massari @naszam
///@notice AntsReview to allows issuer to issue an antReview which peer-reviewers can fulfill
///@dev All function calls are currently implemented without side effects through TDD approach
///@dev OpenZeppelin library is used for secure contract development

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
  enum AntReviewStatus { CREATED, ACCEPTED, CANCELLED }

  /// @dev Token
  AntsToken internal immutable ants;

  /// @dev Counter
  Counters.Counter private _antReviewIdTracker;

  /// @dev Storage
  AntReview[] public antreviews;

  mapping(uint256 => Peer_Review[]) peer_reviews;

  /// @dev Structs
  struct AntReview {
      address payable issuer;
      uint256 deadline;
      string ipfs_hash;
      AntReviewStatus status;
      uint256 amount; //in wei
  }

  struct Peer_Review {
      bool accepted;
      address payable peer_reviewer;
      string ipfs_hash;
  }


  /// @dev Events

  event AntReviewIssued(address issuer, uint256 amount, string ipfsHash);
  event AntReviewFulfilled(uint256 antReviewId, address peer_reviewer, uint256 peerReviewId, string ipfsHash);
  event AntReviewAccepted(uint256 antReviewId, address issuer, address peer_reviewer, uint256 indexed peerReviewId, uint256 amount);
  event AntReviewCancelled(uint256 indexed antReviewId, address indexed issuer, uint256 amount);

  constructor(address ants_) public {
    ants = AntsToken(ants_);
  }

  /// @dev Fallback

  fallback() external payable {
    revert();
  }

  receive() external payable {
    revert();
  }

  /// @dev Modifiers

  modifier hasValue() {
      require(msg.value > 0);
      _;
  }

  modifier antReviewExists(uint256 _antReviewId){
    require(_antReviewId < antreviews.length);
    _;
  }

  modifier peerReviewExists(uint256 _antReviewId, uint256 _peerReviewId){
    require(_peerReviewId < peer_reviews[_antReviewId].length);
    _;
  }

  modifier hasStatus(uint256 _antReviewId, AntReviewStatus _desiredStatus) {
    require(antreviews[_antReviewId].status == _desiredStatus);
    _;
  }

  modifier peerReviewNotYetAccepted(uint256 _antReviewId, uint256 _peerReviewId) {
    require(peer_reviews[_antReviewId][_peerReviewId].accepted == false);
    _;
  }

  modifier validateDeadline(uint256 _newDeadline) {
      require(_newDeadline > now);
      _;
  }

  modifier isBeforeDeadline(uint256 _antReviewId) {
    require(now < antreviews[_antReviewId].deadline);
    _;
  }


  ///@notice Instantiates a new AntReview
  ///@dev Access restricted to Issuer
  ///@param _deadline The unix timestamp after which fulfillments will no longer be accepted
  ///@param _ipfsHash The IPFS Hash of the Scientific Paper
  ///@return True If the antReview is successfully issued
  function issueAntReview(
      string calldata _ipfsHash,
      uint64 _deadline
  )
      external
      payable
      hasValue()
      validateDeadline(_deadline)
      onlyIssuer()
      whenNotPaused()
      returns (bool)
  {
      _antReviewIdTracker.increment();
      antreviews.push(AntReview(msg.sender, _deadline, _ipfsHash, AntReviewStatus.CREATED, msg.value));
      emit AntReviewIssued(msg.sender, msg.value, _ipfsHash);
      return true;
  }


  ///@notice Submit a fulfillment for the given antReview
  ///@dev Access restricted to Peer-Reviewer
  ///@param _antReviewId The index of the antReview to be fufilled
  ///@param _ipfsHash The IPFS Hash which contains evidence of the fufillment
  ///@return True If the AntReview is successfully fulfilled
  function fulfillAntReview(uint256 _antReviewId, string calldata _ipfsHash)
    external
    antReviewExists(_antReviewId)
    onlyPeerReviewer()
    hasStatus(_antReviewId, AntReviewStatus.CREATED)
    isBeforeDeadline(_antReviewId)
    whenNotPaused()
    returns (bool)
  {
    peer_reviews[_antReviewId].push(Peer_Review(false, msg.sender, _ipfsHash));
    emit AntReviewFulfilled(_antReviewId, msg.sender, (peer_reviews[_antReviewId].length.sub(1)),_ipfsHash);
    return true;
  }


  ///@notice Accept a given Peer-Review
  ///@dev Access restricted to Issuer
  ///@param _antReviewId the index of the antReview
  ///@param _peerReviewId the index of the fulfillment being accepted
  ///@return True If the AntReview is successfully being accepted
  function acceptAntReview(uint256 _antReviewId, uint256 _peerReviewId)
      external
      antReviewExists(_antReviewId)
      peerReviewExists(_antReviewId,_peerReviewId)
      onlyIssuer()
      hasStatus(_antReviewId, AntReviewStatus.CREATED)
      peerReviewNotYetAccepted(_antReviewId, _peerReviewId)
      whenNotPaused()
      returns (bool)
  {
      peer_reviews[_antReviewId][_peerReviewId].accepted = true;
      antreviews[_antReviewId].status = AntReviewStatus.ACCEPTED;
      peer_reviews[_antReviewId][_peerReviewId].peer_reviewer.sendValue(antreviews[_antReviewId].amount);
      emit AntReviewAccepted(
        _antReviewId,
        antreviews[_antReviewId].issuer,
        peer_reviews[_antReviewId][_peerReviewId].peer_reviewer,
        _peerReviewId, antreviews[_antReviewId].amount
      );
      return true;
  }


  ///@notice Cancels the antReview and send the funds back to the issuer
  ///@dev Access restricted to Issuer
  ///@param _antReviewId the index of the antReview
  ///@return True If the AntReview is successfully cancelled
  function cancelAntReview(uint256 _antReviewId)
      external
      antReviewExists(_antReviewId)
      onlyIssuer()
      hasStatus(_antReviewId, AntReviewStatus.CREATED)
      whenNotPaused()
      returns (bool)
  {
      antreviews[_antReviewId].status = AntReviewStatus.CANCELLED;
      antreviews[_antReviewId].issuer.sendValue(antreviews[_antReviewId].amount);
      emit AntReviewCancelled(_antReviewId, msg.sender, antreviews[_antReviewId].amount);
      return true;
  }

}

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.8;

///@title AntsReview
///@author Nazzareno Massari
///@notice AntsReview to allows issuer to issue an antReview which peer-reviewers can fulfill
///@dev All function calls are currently implemented without side effecs through TDD approach
///@dev OpenZeppelin library is used for secure contract development

import "./AntsReviewRoles.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface AntToken {
  function transfer(address reciptient, uint amount) external returns (bool);
  function balanceOf(address account) external view returns (uint);
}

contract AntsReview is AntsReviewRoles {

  using SafeMath for uint256;
  using Address for address payable;

  /// Enums
  enum AntReviewStatus { CREATED, ACCEPTED, CANCELLED }

  /// Token
  AntToken internal ant;

  /// Storage
  AntReview[] public antreviews ;

  mapping(uint256 => Fulfillment[]) fulfillments;

  /// Structs
  struct AntReview {
      address payable issuer;
      uint256 deadline;
      string data;
      AntReviewStatus status;
      uint256 amount; //in wei
  }

  struct Fulfillment {
      bool accepted;
      address payable fulfiller;
      string data;
  }


  // Events

  event AntReviewIssued(uint256 antReview_id, address issuer, uint256 amount, string data);
  event AntReviewFulfilled(uint256 antReview_id, address fulfiller, uint256 fulfillment_id, string data);
  event FulfillmentAccepted(uint256 _antReviewId, address issuer, address fulfiller, uint256 indexed fulfillment_id, uint256 amount);
  event AntReviewCancelled(uint256 indexed antReview_id, address indexed issuer, uint256 amount);

  constructor(address ant_) public {
    ant = AntToken(ant_);
  }

  // Fallback

  fallback() external payable {
    revert();
  }

  receive() external payable {
    revert();
  }

  // Modifiers

  modifier hasValue() {
      require(msg.value > 0);
      _;
  }

  modifier antReviewExists(uint256 _antReviewId){
    require(_antReviewId < antreviews.length);
    _;
  }

  modifier fulfillmentExists(uint256 _antReviewId, uint256 _fulfillmentId){
    require(_fulfillmentId < fulfillments[_antReviewId].length);
    _;
  }

  modifier hasStatus(uint256 _antReviewId, AntReviewStatus _desiredStatus) {
    require(antreviews[_antReviewId].status == _desiredStatus);
    _;
  }

  modifier fulfillmentNotYetAccepted(uint256 _antReviewId, uint256 _fulfillmentId) {
    require(fulfillments[_antReviewId][_fulfillmentId].accepted == false);
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

  /**
  * @dev issueAntReview(): instantiates a new bounty
  * @param _deadline the unix timestamp after which fulfillments will no longer be accepted
  * @param _data the requirements of the antReview
  */
  function issueAntReview(
      string calldata _data,
      uint64 _deadline
  )
      external
      payable
      hasValue()
      validateDeadline(_deadline)
      onlyIssuer()
      whenNotPaused()
      returns (uint256)
  {
      antreviews.push(AntReview(msg.sender, _deadline, _data, AntReviewStatus.CREATED, msg.value));
      emit AntReviewIssued(antreviews.length.sub(1),msg.sender, msg.value, _data);
      return (antreviews.length.sub(1));
  }

  /**
  * @dev fulfillAntReview(): submit a fulfillment for the given antReview
  * @param _antReviewId the index of the antReview to be fufilled
  * @param _data the ipfs hash which contains evidence of the fufillment
  */
  function fulfillAntReview(uint256 _antReviewId, string memory _data)
    public
    antReviewExists(_antReviewId)
    onlyPeerReviewer()
    hasStatus(_antReviewId, AntReviewStatus.CREATED)
    isBeforeDeadline(_antReviewId)
    whenNotPaused()
  {
    fulfillments[_antReviewId].push(Fulfillment(false, msg.sender, _data));
    emit AntReviewFulfilled(_antReviewId, msg.sender, (fulfillments[_antReviewId].length.sub(1)),_data);
  }

  /**
  * @dev acceptFulfillment(): accept a given fulfillment
  * @param _antReviewId the index of the antReview
  * @param _fulfillmentId the index of the fulfillment being accepted
  */
  function acceptFulfillment(uint256 _antReviewId, uint256 _fulfillmentId)
      public
      antReviewExists(_antReviewId)
      fulfillmentExists(_antReviewId,_fulfillmentId)
      onlyIssuer()
      hasStatus(_antReviewId, AntReviewStatus.CREATED)
      fulfillmentNotYetAccepted(_antReviewId, _fulfillmentId)
      whenNotPaused()
  {
      fulfillments[_antReviewId][_fulfillmentId].accepted = true;
      antreviews[_antReviewId].status = AntReviewStatus.ACCEPTED;
      fulfillments[_antReviewId][_fulfillmentId].fulfiller.sendValue(antreviews[_antReviewId].amount);
      emit FulfillmentAccepted(
        _antReviewId,
        antreviews[_antReviewId].issuer,
        fulfillments[_antReviewId][_fulfillmentId].fulfiller,
        _fulfillmentId, antreviews[_antReviewId].amount
      );
  }

  /** @dev cancelAntReview(): cancels the antReview and send the funds back to the issuer
  * @param _antReviewId the index of the antReview
  */
  function cancelAntReview(uint256 _antReviewId)
      public
      antReviewExists(_antReviewId)
      onlyIssuer()
      hasStatus(_antReviewId, AntReviewStatus.CREATED)
      whenNotPaused()
  {
      antreviews[_antReviewId].status = AntReviewStatus.CANCELLED;
      antreviews[_antReviewId].issuer.sendValue(antreviews[_antReviewId].amount);
      emit AntReviewCancelled(_antReviewId, msg.sender, antreviews[_antReviewId].amount);
  }

}

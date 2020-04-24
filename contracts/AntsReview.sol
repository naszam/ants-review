pragma solidity ^0.6.0;

/**
 * @title AntsReview
 * @author Nazzareno Massari, Bianca Trovò
 * @dev Simple smart contract which allows any user to issue an antReview in ETH linked to requirements stored in ipfs
 * which anyone can fufill by submitting the ipfs hash which contains evidence of their fufillment
 */
contract AntsReview {


  // Enums


  enum AntReviewStatus { CREATED, ACCEPTED, CANCELLED }


  // Storage


  AntReview[] public antreviews ;

  mapping(uint=>Fulfillment[]) fulfillments;


  // Structs


  struct AntReview {
      address payable issuer;
      uint deadline;
      string data;
      AntReviewStatus status;
      uint amount; //in wei
  }

  struct Fulfillment {
      bool accepted;
      address payable fulfiller;
      string data;
  }


  // Events

  event AntReviewIssued(uint antReview_id, address issuer, uint amount, string data);
  event AntReviewFulfilled(uint antReview_id, address fulfiller, uint fulfillment_id, string data);
  event FulfillmentAccepted(uint antReview_id, address issuer, address fulfiller, uint indexed fulfillment_id, uint amount);
  event AntReviewCancelled(uint indexed antReview_id, address indexed issuer, uint amount);

  constructor() public {}


  // Modifiers

  modifier hasValue() {
      require(msg.value > 0);
      _;
  }

  modifier antReviewExists(uint _antReviewId){
    require(_antReviewId < antreviews.length);
    _;
  }

  modifier fulfillmentExists(uint _antReviewId, uint _fulfillmentId){
    require(_fulfillmentId < fulfillments[_antReviewId].length);
    _;
  }

  modifier hasStatus(uint _antReviewId, AntReviewStatus _desiredStatus) {
    require(antreviews[_antReviewId].status == _desiredStatus);
    _;
  }

  modifier onlyIssuer(uint _antReviewId) {
      require(msg.sender == antreviews[_antReviewId].issuer);
      _;
  }

  modifier notIssuer(uint _antReviewId) {
      require(msg.sender != antreviews[_antReviewId].issuer);
      _;
  }

  modifier fulfillmentNotYetAccepted(uint _antReviewId, uint _fulfillmentId) {
    require(fulfillments[_antReviewId][_fulfillmentId].accepted == false);
    _;
  }

  modifier validateDeadline(uint _newDeadline) {
      require(_newDeadline > now);
      _;
  }

  modifier isBeforeDeadline(uint _antReviewId) {
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
      returns (uint)
  {
      antreviews.push(AntReview(msg.sender, _deadline, _data, AntReviewStatus.CREATED, msg.value));
      emit AntReviewIssued(antreviews.length - 1,msg.sender, msg.value, _data);
      return (antreviews.length - 1);
  }

  /**
  * @dev fulfillAntReview(): submit a fulfillment for the given antReview
  * @param _antReviewId the index of the antReview to be fufilled
  * @param _data the ipfs hash which contains evidence of the fufillment
  */
  function fulfillAntReview(uint _antReviewId, string memory _data)
    public
    antReviewExists(_antReviewId)
    notIssuer(_antReviewId)
    hasStatus(_antReviewId, AntReviewStatus.CREATED)
    isBeforeDeadline(_antReviewId)
  {
    fulfillments[_antReviewId].push(Fulfillment(false, msg.sender, _data));
    emit AntReviewFulfilled(_antReviewId, msg.sender, (fulfillments[_antReviewId].length - 1),_data);
  }

  /**
  * @dev acceptFulfillment(): accept a given fulfillment
  * @param _antReviewId the index of the antReview
  * @param _fulfillmentId the index of the fulfillment being accepted
  */
  function acceptFulfillment(uint _antReviewId, uint _fulfillmentId)
      public
      antReviewExists(_antReviewId)
      fulfillmentExists(_antReviewId,_fulfillmentId)
      onlyIssuer(_antReviewId)
      hasStatus(_antReviewId, AntReviewStatus.CREATED)
      fulfillmentNotYetAccepted(_antReviewId, _fulfillmentId)
  {
      fulfillments[_antReviewId][_fulfillmentId].accepted = true;
      antreviews[_antReviewId].status = AntReviewStatus.ACCEPTED;
      fulfillments[_antReviewId][_fulfillmentId].fulfiller.transfer(antreviews[_antReviewId].amount);
      emit FulfillmentAccepted(_antReviewId, antreviews[_antReviewId].issuer, fulfillments[_antReviewId][_fulfillmentId].fulfiller, _fulfillmentId, antreviews[_antReviewId].amount);
  }

  /** @dev cancelAntReview(): cancels the antReview and send the funds back to the issuer
  * @param _antReviewId the index of the antReview
  */
  function cancelAntReview(uint _antReviewId)
      public
      antReviewExists(_antReviewId)
      onlyIssuer(_antReviewId)
      hasStatus(_antReviewId, AntReviewStatus.CREATED)
  {
      antreviews[_antReviewId].status = AntReviewStatus.CANCELLED;
      antreviews[_antReviewId].issuer.transfer(antreviews[_antReviewId].amount);
      emit AntReviewCancelled(_antReviewId, msg.sender, antreviews[_antReviewId].amount);
  }

}

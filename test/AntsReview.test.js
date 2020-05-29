let catchRevert = require("./exceptionsHelpers.js").catchRevert
var Ant = artifacts.require('./Ant')
var AntsReview = artifacts.require('./AntsReview')

contract('AntsReview', function(accounts) {

  const owner = accounts[0]
  const issuer = accounts[1]
  const peer_reviewer = accounts[3]
  const random = accounts[4]

  const DEFAULT_ADMIN_ROLE = "0x00"

  const ipfsHash = "QmaozNR7DZHQK1ZcU9p7QdrshMvXqWK6gpu5rmrkPdT3L4"
  var date = new Date()
  const timestamp = date.getTime()
  const deadline = timestamp + 31556926 // 1 year in seconds (365.24 days)
  //console.log(timestamp)
  const antReviewId = "0"
  const peerReviewId = "0"

  let instance

  // Before Each
  beforeEach(async () => {
    token = await Ant.new()
    instance = await AntsReview.new(Ant.address)
  })

  // Check that the owner is set as the deploying address
  // Check that the owner is set as admin when the contract is deployed
  // Check that the owner is set as templater when the contract is deployed
  // Check that the owner is the only admin when the contract is deployed
  describe("Setup", async() => {

      it("OWNER should be set to the deploying address", async() => {
          const ownerAddress = await instance.owner()
          assert.equal(ownerAddress, owner, "the deploying address should be the owner")
      })

      it("OWNER should be set as the default admin when the contract is created", async() => {
          const admin = await instance.isAdmin(owner, {from:random})
          assert.isTrue(admin, "the owner should be set as the default admin")
      })

      it("Owner should be the only admin when the contract is created", async() => {
          const admins = await instance.getRoleMemberCount(DEFAULT_ADMIN_ROLE)
          assert.equal(admins, "1", "the owner should be the only admin")
      })


  })

  describe("Functions", () => {

    // Check issueAntReview() for success when an issuer is issuing a new AntReview
    // Check issueAntReview() for sucessfully emit event when the AntReview is Issued
    // Check issueAntReview() for failure when a random address try to issue an AntReview
    describe("issueAntReview()", async () => {

      it("issuers should be able to issue a new AntReview", async () => {
        await instance.addIssuer(issuer, {from: owner})
        await instance.issueAntReview(ipfsHash, deadline, {from:issuer, value: 1})
      })

      it("should emit the appropriate event when an AntReview is issued", async () => {
        await instance.addIssuer(issuer, {from: owner})
        const result = await instance.issueAntReview(ipfsHash, deadline, {from:issuer, value: 1})
        assert.equal(result.logs[0].event, "AntReviewIssued", "AntReviewIssued event not emitted, check issueAntReview method")
      })

      it("random address should not be able to issue a new AntReview", async () => {
        await instance.addIssuer(issuer, {from: owner})
        await catchRevert(instance.issueAntReview(ipfsHash, deadline, {from:random, value: 1}))
      })
    })

    // Check fulfillAntReview() for success when a peer_reviewer is fulfilling an AntReview
    // Check fulfillAntReview() for sucessfully emit event when the AntReview is Fulfilled
    // Check fulfillAntReview() for failure when a random address try to fulfill an AntReview
    describe("fulfillAntReview", async () => {

      it("peer_reviewers should be able to fulfill an AntReview", async () => {
        await instance.addIssuer(issuer, {from: owner})
        await instance.addPeerReviewer(peer_reviewer, {from: owner})
        await instance.issueAntReview(ipfsHash, deadline, {from:issuer, value: 1})
        await instance.fulfillAntReview(antReviewId, ipfsHash, {from: peer_reviewer})
      })

      it("should emit the appropriate event when the AntReview is fulfilled", async () => {
        await instance.addIssuer(issuer, {from: owner})
        await instance.addPeerReviewer(peer_reviewer, {from: owner})
        await instance.issueAntReview(ipfsHash, deadline, {from:issuer, value: 1})
        const result = await instance.fulfillAntReview(antReviewId, ipfsHash, {from: peer_reviewer})
        assert.equal(result.logs[0].event, "AntReviewFulfilled", "AntReviewFulfilled event not emitted, check fulfillAntReview method")
      })

      it("random address should not be able to fulfill an AntReview", async () => {
        await instance.addIssuer(issuer, {from: owner})
        await instance.addPeerReviewer(peer_reviewer, {from: owner})
        await instance.issueAntReview(ipfsHash, deadline, {from:issuer, value: 1})
        await catchRevert(instance.fulfillAntReview(antReviewId, ipfsHash, {from: random}))
      })
    })

    // Check acceptAntReview() for success when an issuer is accepting an AntReview
    // Check acceptAntReview() for sucessfully emit event when the AntReview is accepted
    // Check acceptAntReview() for failure when a random address try to accept an AntReview
    describe("acceptAntReview()", async () => {

      it("issuers should be able to accept an AntReview", async () => {
        await instance.addIssuer(issuer, {from: owner})
        await instance.issueAntReview(ipfsHash, deadline, {from:issuer, value: 1})
        await instance.addPeerReviewer(peer_reviewer, {from: owner})
        await instance.fulfillAntReview(antReviewId, ipfsHash, {from: peer_reviewer})
        await instance.acceptAntReview(antReviewId, peerReviewId, {from: issuer})
      })

      it("should emit the appropriate event when an AntReview is accepted", async () => {
        await instance.addIssuer(issuer, {from: owner})
        await instance.issueAntReview(ipfsHash, deadline, {from:issuer, value: 1})
        await instance.addPeerReviewer(peer_reviewer, {from: owner})
        await instance.fulfillAntReview(antReviewId, ipfsHash, {from: peer_reviewer})
        const result = await instance.acceptAntReview(antReviewId, peerReviewId, {from: issuer})
        assert.equal(result.logs[0].event, "AntReviewAccepted", "AntReviewAccepted event not emitted, check acceptAntReview method")
      })

      it("random address should not be able to accept an AntReview", async () => {
        await instance.addIssuer(issuer, {from: owner})
        await instance.issueAntReview(ipfsHash, deadline, {from:issuer, value: 1})
        await instance.addPeerReviewer(peer_reviewer, {from: owner})
        await instance.fulfillAntReview(antReviewId, ipfsHash, {from: peer_reviewer})
        await catchRevert(instance.acceptAntReview(antReviewId, peerReviewId, {from: random}))
      })
    })

    // Check cancelAntReview() for success when an issuer is cancelling an AntReview
    // Check cancelAntReview() for sucessfully emit event when the AntReview is cancelled
    // Check cancelAntReview() for failure when a random address try to cancel an AntReview
    describe("cancelAntReview()", async () => {

      it("issuers should be able to cancel an AntReview", async () => {
        await instance.addIssuer(issuer, {from: owner})
        await instance.issueAntReview(ipfsHash, deadline, {from:issuer, value: 1})
        await instance.cancelAntReview(antReviewId, {from: issuer})
      })

      it("should emit the appropriate event when an AntReview is cancelled", async () => {
        await instance.addIssuer(issuer, {from: owner})
        await instance.issueAntReview(ipfsHash, deadline, {from:issuer, value: 1})
        const result = await instance.cancelAntReview(antReviewId, {from: issuer})
        assert.equal(result.logs[0].event, "AntReviewCancelled", "AntReviewCancelled event not emitted, check cancelAntReview method")
      })

      it("random address should not be able to cancel an AntReview", async () => {
        await instance.addIssuer(issuer, {from: owner})
        await instance.issueAntReview(ipfsHash, deadline, {from:issuer, value: 1})
        await catchRevert(instance.cancelAntReview(antReviewId, {from: random}))
      })
    })
  })
})

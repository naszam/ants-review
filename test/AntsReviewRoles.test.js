let catchRevert = require("./exceptionsHelpers.js").catchRevert
var AntsReviewRoles = artifacts.require('./AntsReviewRoles')

contract('AntsReviewRoles', function(accounts) {

  const owner = accounts[0]
  const issuer = accounts[1]
  const peer_reviewer = accounts[3]
  const random = accounts[4]

  const DEFAULT_ADMIN_ROLE = "0x00"


  let instance

  // Before Each
  beforeEach(async () => {
    instance = await AntsReviewRoles.new()
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

    // Check addIssuer() for success when an admin is adding a new issuer
    // Check addIssuer() for sucessfully emit event when the issuer is added
    // Check addIssuer() for failure when a random address try to add an issuer
    describe("addIssuer()", async () => {

      it("admin should be able to add a new issuer", async () => {
        await instance.addIssuer(issuer, {from:owner})
        const issuerAdded = await instance.isIssuer(issuer, {from:random})
        assert.isTrue(issuerAdded, "only admins can add a new issuer")
      })

      it("should emit the appropriate event when a new issuer is added", async () => {
        const result = await instance.addIssuer(issuer, {from:owner})
        assert.equal(result.logs[0].event, "RoleGranted", "RoleGranted event not emitted, check addIssuer method")
      })

      it("random address should not be able to add a new issuer", async () => {
        await catchRevert(instance.addIssuer(issuer, {from:random}))
      })
    })

    // Check addPeerReviewer() for success when an admin is adding a new peer reviewer
    // Check addPeerReviewer() for sucessfully emit event when the peer_reviewer is added
    // Check addPeerReviewer() for failure when a random address try to add a peer_reviewer
    describe("addPeerReviewer()", async () => {

      it("admin should be able to add a new peer_reviewer", async () => {
        await instance.addPeerReviewer(peer_reviewer, {from:owner})
        const peerReviewerAdded = await instance.isPeerReviewer(peer_reviewer, {from:random})
        assert.isTrue(peerReviewerAdded, "only admins can add a new peer_reviewer")
      })

      it("should emit the appropriate event when a new peer_reviewer is added", async () => {
        const result = await instance.addPeerReviewer(peer_reviewer, {from:owner})
        assert.equal(result.logs[0].event, "RoleGranted", "RoleGranted event not emitted, check addPeerReviewer method")
      })

      it("random address should not be able to add a new peer_reviewer", async () => {
        await catchRevert(instance.addPeerReviewer(peer_reviewer, {from:random}))
      })
    })


    // Check pause() for success when a pauser is pausing all the functions
    // Check pause() for sucessfully emit event when the functions are paused
    // Check pause() for failure when a random address try to pause all the functions
    describe("pause()", async () => {

      it("pauser should be able to pause all the functions", async () => {
        await instance.pause({from:owner})
        await catchRevert(instance.pause({from:owner}))
      })

      it("should emit the appropriate event when the functions are paused", async () => {
        const result = await instance.pause({from:owner})
        assert.equal(result.logs[0].event, "Paused", "Paused event not emitted, check pause method")
      })

      it("random address should not be able to pause all functions", async () => {
        await catchRevert(instance.pause({from:random}))
      })
    })

    // Check unpause() for success when an amdin is unpausing all the functions
    // Check unpause() for sucessfully emit event when the functions are unpaused
    // Check unpause() for failure when a random address try to unpause all the functions
    describe("unpause()", async () => {

      it("admins should be able to unpause all the functions", async () => {
        await instance.pause({from:owner})
        await instance.unpause({from:owner})
        await catchRevert(instance.unpause({from:owner}))
      })

      it("should emit the appropriate event when all functions are unpaused", async () => {
        await instance.pause({from:owner})
        const result = await instance.unpause({from:owner})
        assert.equal(result.logs[0].event, "Unpaused", "Unpaused event not emitted, check pause method")
      })

      it("random address should not be able to unpause all the functions", async () => {
        await instance.pause({from:owner})
        await catchRevert(instance.unpause({from:random}))
      })
    })
  })
})

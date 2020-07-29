// test/AntsReviewRoles.test.js

const { accounts, contract, web3 } = require('@openzeppelin/test-environment');

const { expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

const { expect } = require('chai');

const AntsReviewRoles = contract.fromArtifact('AntsReviewRoles');

let roles;

describe('AntsReviewRoles', function () {
const [ owner, issuer, peer_reviewer, other ] = accounts;

const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';
const PAUSER_ROLE = web3.utils.soliditySha3('PAUSER_ROLE');
const ISSUER_ROLE = web3.utils.soliditySha3('ISSUER_ROLE');
const PEER_REVIEWER_ROLE = web3.utils.soliditySha3('PEER_REVIEWER_ROLE');

  beforeEach(async function () {
    roles = await AntsReviewRoles.new({ from: owner })
  });

  it('the deployer is the owner', async function () {
    expect(await roles.owner()).to.equal(owner);
  });

  it('owner has the default admin role', async function () {
    expect(await roles.getRoleMemberCount(DEFAULT_ADMIN_ROLE)).to.be.bignumber.equal('1');
    expect(await roles.getRoleMember(DEFAULT_ADMIN_ROLE, 0)).to.equal(owner);
  });

  it('owner has the pauser role', async function () {
    expect(await roles.getRoleMemberCount(PAUSER_ROLE)).to.be.bignumber.equal('1');
    expect(await roles.getRoleMember(PAUSER_ROLE, 0)).to.equal(owner);
  });

  // Check addIssuer() for success when an admin is adding a new issuer
  // Check addIssuer() for sucessfully emit event when the issuer is added
  // Check addIssuer() for failure when a random address try to add an issuer
  describe("addIssuer()", async () => {

      it("admin should be able to add a new issuer", async () => {
        await roles.addIssuer(issuer, {from:owner})
        expect(await roles.getRoleMember(ISSUER_ROLE, 0)).to.equal(issuer)
      })

      it("should emit the appropriate event when a new issuer is added", async () => {
        const receipt = await roles.addIssuer(issuer, {from:owner})
        expectEvent(receipt, "RoleGranted", { account: issuer })
      })

      it("other address should not be able to add a new issuer", async () => {
        await expectRevert(roles.addIssuer(issuer, {from:other}), 'Caller is not an admin')
      })
  })

  // Check addPeerReviewer() for success when an admin is adding a new peer reviewer
  // Check addPeerReviewer() for sucessfully emit event when the peer_reviewer is added
  // Check addPeerReviewer() for failure when a random address try to add a peer_reviewer
  describe("addPeerReviewer()", async () => {

      it("admin should be able to add a new peer_reviewer", async () => {
        await roles.addPeerReviewer(peer_reviewer, {from:owner})
        expect(await roles.getRoleMember(PEER_REVIEWER_ROLE, 0)).to.equal(peer_reviewer)
      })

      it("should emit the appropriate event when a new peer_reviewer is added", async () => {
        const receipt = await roles.addPeerReviewer(peer_reviewer, {from:owner})
        expectEvent(receipt, "RoleGranted", { account: peer_reviewer })
      })

      it("other address should not be able to add a new peer_reviewer", async () => {
        await expectRevert(roles.addPeerReviewer(peer_reviewer, {from:other}), 'Caller is not an admin')
      })
  })

  // Check removeIssuer() for success when an admin is removing a new issuer
  // Check removeIssuer() for sucessfully emit event when the issuer is removed
  // Check removeIssuer() for failure when a random address try to remove an issuer
  describe("removeIssuer()", async () => {

      beforeEach(async () => {
        await roles.addIssuer(issuer, {from: owner})
      })

      it("admin should be able to remove an issuer", async () => {
        await roles.removeIssuer(issuer, {from:owner})
        expect(await roles.hasRole(ISSUER_ROLE, issuer)).to.equal(false)
      })

      it("should emit the appropriate event when an issuer is removed", async () => {
        const receipt = await roles.removeIssuer(issuer, {from:owner})
        expectEvent(receipt, "RoleRevoked", { account: issuer })
      })

      it("other address should not be able to remove an issuer", async () => {
        await expectRevert(roles.removeIssuer(issuer, {from:other}), 'Caller is not an admin')
      })
  })

  // Check removePeerReviewer() for success when an admin is removing a peer_reviewer
  // Check removePeerReviewer() for sucessfully emit event when the peer_reviewer is removed
  // Check removePeerReviewer() for failure when a random address try to remove a peer_reviewer
  describe("removePeerReviewer()", async () => {

      beforeEach(async () => {
        await roles.addPeerReviewer(peer_reviewer, {from: owner})
      })

      it("admin should be able to remove a peer_reviewer", async () => {
        await roles.removePeerReviewer(peer_reviewer, {from:owner})
        expect(await roles.hasRole(PEER_REVIEWER_ROLE, peer_reviewer)).to.equal(false)
      })

      it("should emit the appropriate event when a peer_reviewer is removed", async () => {
        const receipt = await roles.removePeerReviewer(peer_reviewer, {from:owner})
        expectEvent(receipt, "RoleRevoked", { account: peer_reviewer })
      })

      it("other address should not be able to remove a peer_reviewer", async () => {
        await expectRevert(roles.removePeerReviewer(peer_reviewer, {from:other}), 'Caller is not an admin')
      })
  })

  describe('pausing', function () {
      it('owner can pause', async function () {
        const receipt = await roles.pause({ from: owner });
        expectEvent(receipt, 'Paused', { account: owner });

        expect(await roles.paused()).to.equal(true);
      });

      it('owner can unpause', async function () {
        await roles.pause({ from: owner });

        const receipt = await roles.unpause({ from: owner });
        expectEvent(receipt, 'Unpaused', { account: owner });

        expect(await roles.paused()).to.equal(false);
      });

      it('other accounts cannot pause', async function () {
        await expectRevert(roles.pause({ from: other }), 'AntsReview: must have pauser role to pause');
      });
  });

})

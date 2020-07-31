// test/AntsReviewRoles.test.js

const { accounts, contract, web3 } = require('@openzeppelin/test-environment');

const { BN, expectEvent, expectRevert, time, ether } = require('@openzeppelin/test-helpers');

const { expect } = require('chai');


const ANTS = contract.fromArtifact('ANTS');
const AntsFaucet = contract.fromArtifact('AntsFaucet');
const AntsReview = contract.fromArtifact('AntsReview');

let antsreview;

describe('AntsReview', function () {
const [ owner, issuer, approver, peer_reviewer, anter, other, approver2, issuer1, issuer2, issuer3 ] = accounts;


const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';

const issuers = [issuer, issuer1];
const issuers2 = [issuer2, issuer3];
const paperHash = "QmaozNR7DZHQK1ZcU9p7QdrshMvXqWK6gpu5rmrkPdT3L4";
const paperHash2 = "QmXnKpwTjTVGynndbzQSRb4yz7ebYgWfocSgfztsx8s2Zo";
const requirementsHash = "QmW2WQi7j6c7UgJTarActp7tDNikE4B2qXtFCfLPdsgaTQ";
const requirementsHash2 = "QmT9qk3CRYbFDWpDFYeAv8T8H1gnongwKhh5J68NLkLir6";
const reviewHash = "Qmd286K6pohQcTKYqnS1YhWrCiS4gz7Xi34sdwMe9USZ7u";
const reviewHash2 = "QmRW3V9znzFW9M5FYbitSEvd5dQrPWGvPvgQD6LM22Tv8D"
const antId = "0";
const reviewId = "0";
const issuerId = "1";
const approverId = "1";
const contributionId = "0";
const amount = ether('100');
const tokens = ether('1');
const allowance = ether('10');


  before(async function () {
    // Advance to the next block to correctly read time in the solidity "now" function interpreted by ganache
    await time.advanceBlock();
  });

  beforeEach(async function () {
    deadline = (await time.latest()).add(time.duration.weeks(1));
    deadline2 = (await time.latest()).add(time.duration.weeks(2));

    ants = await ANTS.new({from: owner});
    faucet = await AntsFaucet.new(ants.address, {from: owner});
    antsreview= await AntsReview.new(ants.address, { from: owner });
  });

  it('the deployer is the owner', async function () {
    expect(await antsreview.owner()).to.equal(owner);
  });

  // Check issueAntReview() for success when an issuer is issuing a new AntReview
  // Check issueAntReview() for sucessfully emit event when the AntReview is Issued
  // Check issueAntReview() for failure when a random address try to issue an AntReview
  describe("issueAntReview()", async function () {

    it("issuers should be able to issue a new AntReview", async function () {
      await antsreview.addIssuer(issuer, {from: owner});
      await antsreview.issueAntReview(issuers, approver, paperHash, requirementsHash, deadline, {from: issuer});
      const receipt = await antsreview.antreviews(antId, {from: other});
      expect(receipt.paperHash).to.equal(paperHash);
      expect(receipt.requirementsHash).to.equal(requirementsHash);
      expect(receipt.deadline).to.be.bignumber.equal(deadline);
      expect(receipt.balance).to.be.bignumber.equal('0');
      expect(await antsreview.getApprover(antId, '0', {from: other})).to.equal(approver);
    })

    it("should emit the appropriate event when an AntReview is issued", async function () {
      await antsreview.addIssuer(issuer, {from: owner})
      const receipt = await antsreview.issueAntReview(issuers, approver, paperHash, requirementsHash, deadline, {from: issuer});
      expectEvent(receipt, "AntReviewIssued", { antId: antId, issuers: issuers, paperHash: paperHash, requirementsHash: requirementsHash, deadline: deadline })
      })

    it("random address should not be able to issue a new AntReview", async function () {
      await expectRevert(antsreview.issueAntReview(issuers, approver, paperHash, requirementsHash, deadline, {from: issuer}), 'Caller is not an issuer')
    })

  })

  describe("changeAntReview()", async function () {

    beforeEach(async function () {
      await antsreview.addIssuer(issuer, {from: owner});
      await antsreview.issueAntReview(issuers, approver, paperHash, requirementsHash, deadline, {from: issuer});
    });

    it("issuers should be able to change an AntReview", async function () {
      await antsreview.changeAntReview(antId, issuerId, issuers2, paperHash2, requirementsHash2, deadline2, {from: issuer1});
      const receipt = await antsreview.antreviews(antId, {from: other});
      expect(receipt.paperHash).to.equal(paperHash2);
      expect(receipt.requirementsHash).to.equal(requirementsHash2);
      expect(receipt.deadline).to.be.bignumber.equal(deadline2);
    })

    it("should emit the appropriate event when an AntReview is issued", async function () {
      const receipt = await antsreview.changeAntReview(antId, issuerId, issuers2, paperHash2, requirementsHash2, deadline2, {from: issuer1});
      expectEvent(receipt, "AntReviewChanged", { antId: antId, issuer: issuer1, issuers: issuers2, paperHash: paperHash2, requirementsHash: requirementsHash2, deadline: deadline2 })
      })

    it("random address should not be able to change an AntReview", async function () {
      await expectRevert(antsreview.changeAntReview(antId, issuerId, issuers2, paperHash2, requirementsHash2, deadline2, {from: other}), 'Caller is not the issuer')
    })

  })

  describe("addApprover()", async function () {

    beforeEach(async function () {
      await antsreview.addIssuer(issuer, {from: owner});
      await antsreview.issueAntReview(issuers, approver, paperHash, requirementsHash, deadline, {from: issuer});
    });

    it("issuer should be able to add a new Approver", async function () {
      await antsreview.addApprover(antId, issuerId, approver2, {from: issuer1});
      const receipt = await antsreview.getApprover(antId, approverId, {from: other});
      expect (receipt).to.equal(approver2);
    })

    it("should emit the appropriate event when an approver is added", async function () {
      const receipt = await antsreview.addApprover(antId, issuerId, approver2, {from: issuer1});
      expectEvent(receipt, "ApproverAdded", { antId: antId, issuerId: issuerId, approver: approver2 })
      })

    it("random address should not be able to add an approver", async function () {
      await expectRevert(antsreview.addApprover(antId, issuerId, approver2, {from: other}), 'Caller is not the issuer');
    })

  })


  describe("contribute()", async function () {

    beforeEach(async function () {
      await antsreview.addIssuer(issuer, {from: owner});
      await antsreview.addPeerReviewer(peer_reviewer, {from: owner});
      await antsreview.issueAntReview(issuers, approver, paperHash, requirementsHash, deadline, {from: issuer});
      await ants.mint(faucet.address, amount, {from: owner});
      await faucet.withdraw({ from: anter });
      await ants.increaseAllowance(antsreview.address, allowance, {from: anter})

    });

    it("Anters can contribute to an AntReview", async function () {
      const decimals = await ants.decimals({from: other});
      const tokenbits = (new BN(10)).pow(decimals);
      const amount = (new BN(1)).mul(tokenbits);

      await antsreview.contribute(antId, tokens, {from: anter});
      const receipt = await antsreview.antreviews(antId, {from: other});
      expect(receipt.balance).to.be.bignumber.equal(tokens);
    })

    it("should emit the appropriate event when an Contribution is Added", async function () {
      const receipt = await antsreview.contribute(antId, tokens, {from: anter});
      expectEvent(receipt, "ContributionAdded", { antId: antId, contributionId: contributionId, contributor: anter, amount: tokens });
    })
  })

  describe("refund()", async function () {

    beforeEach(async function () {
      await antsreview.addIssuer(issuer, {from: owner});
      await antsreview.addPeerReviewer(peer_reviewer, {from: owner});
      await antsreview.issueAntReview(issuers, approver, paperHash, requirementsHash, deadline, {from: issuer});
      await ants.mint(faucet.address, amount, {from: owner});
      await faucet.withdraw({ from: anter });
      await ants.increaseAllowance(antsreview.address, allowance, {from: anter})
      await antsreview.contribute(antId, tokens, {from: anter});
    });

    it("Anters can get a refund for their contributions", async function () {
      await time.increase(time.duration.weeks(2));
      await antsreview.refund(antId, contributionId, {from: anter});
      expect(await ants.balanceOf(antsreview.address)).to.be.bignumber.equal('0');
    })

    it("should emit the appropriate event when an Contribution is Added", async function () {
      await time.increase(time.duration.weeks(2));
      const receipt = await antsreview.refund(antId, contributionId, {from: anter});
      expectEvent(receipt, "ContributionRefunded", { antId: antId, contributionId: contributionId, contributor: anter});
    })
  })

  // Check fulfillAntReview() for success when a peer_reviewer is fulfilling an AntReview
  // Check fulfillAntReview() for sucessfully emit event when the AntReview is Fulfilled
  // Check fulfillAntReview() for failure when a random address try to fulfill an AntReview
  describe("fulfillAntReview()", async function () {

    beforeEach(async function () {
      await antsreview.addIssuer(issuer, {from: owner});
      await antsreview.addPeerReviewer(peer_reviewer, {from: owner});
      await antsreview.issueAntReview(issuers, approver, paperHash, requirementsHash, deadline, {from: issuer});
    });

    it("peer_reviewers should be able to fulfill an AntReview", async function () {
      await antsreview.fulfillAntReview(antId, reviewHash, {from: peer_reviewer});
      const receipt = await antsreview.peer_reviews(antId, reviewId, {from: other});
      expect(receipt.accepted).to.equal(false);
      expect(receipt.peer_reviewer).to.equal(peer_reviewer);
      expect(receipt.reviewHash).to.equal(reviewHash);
    })

    it("should emit the appropriate event when the AntReview is fulfilled", async () => {
      const receipt = await antsreview.fulfillAntReview(antId, reviewHash, {from: peer_reviewer});
      expectEvent(receipt, "AntReviewFulfilled", { antId: antId, reviewId: reviewId, peer_reviewer: peer_reviewer, reviewHash: reviewHash });
    })

    it("random address should not be able to fulfill an AntReview", async () => {
      await expectRevert(antsreview.fulfillAntReview(antId, reviewHash, {from: other}), 'Caller is not a peer-reviewer');
    })
  })

  describe("updateReview()", async function () {

    beforeEach(async function () {
      await antsreview.addIssuer(issuer, {from: owner});
      await antsreview.addPeerReviewer(peer_reviewer, {from: owner});
      await antsreview.issueAntReview(issuers, approver, paperHash, requirementsHash, deadline, {from: issuer});
      await antsreview.fulfillAntReview(antId, reviewHash, {from: peer_reviewer});
    });

    it("peer_reviewers should be able to update a Review", async function () {
      await antsreview.updateReview(antId, reviewId, reviewHash2, {from: peer_reviewer});
      const receipt = await antsreview.peer_reviews(antId, reviewId, {from: other});
      expect(receipt.reviewHash).to.equal(reviewHash2);
    })

    it("should emit the appropriate event when a Review is updated", async () => {
      const receipt = await antsreview.updateReview(antId, reviewId, reviewHash2, {from: peer_reviewer});
      expectEvent(receipt, "ReviewUpdated", { antId: antId, reviewId: reviewId, reviewHash: reviewHash2});
    })

    it("random address should not be able to fulfill an AntReview", async () => {
      await expectRevert(antsreview.updateReview(antId, reviewId, reviewHash2, {from: other}), 'Caller is not the submitter');
    })
  })

  // Check acceptAntReview() for success when an issuer is accepting an AntReview
  // Check acceptAntReview() for sucessfully emit event when the AntReview is accepted
  // Check acceptAntReview() for failure when a random address try to accept an AntReview
  describe("acceptAntReview()", async function () {

    beforeEach(async function () {
      await antsreview.addIssuer(issuer, {from: owner});
      await antsreview.addPeerReviewer(peer_reviewer, {from: owner});
      await antsreview.issueAntReview(issuers, approver, paperHash, requirementsHash, deadline, {from: issuer});
      await ants.mint(faucet.address, amount, {from: owner});
      await faucet.withdraw({ from: anter });
      await ants.increaseAllowance(antsreview.address, allowance, {from: anter})
      await antsreview.contribute(antId, tokens, {from: anter});
      await antsreview.fulfillAntReview(antId, reviewHash, {from: peer_reviewer});
    });

    it("approver should be able to accept an AntReview", async function () {
      await antsreview.acceptAntReview(antId, reviewId, tokens, {from: approver});
      expect(await ants.balanceOf(peer_reviewer)).to.be.bignumber.equal(tokens);
    })

    it("should emit the appropriate event when an AntReview is accepted", async function () {
      const receipt = await antsreview.acceptAntReview(antId, reviewId, tokens, {from: approver});
      expectEvent(receipt, "AntReviewAccepted", { antId: antId, reviewId: reviewId, approver: approver, amount: tokens });
    })

    it("random address should not be able to accept an AntReview", async function () {
      await expectRevert(antsreview.acceptAntReview(antId, reviewId, tokens, {from: other}), 'Caller is not the approver');
    })
  })

})

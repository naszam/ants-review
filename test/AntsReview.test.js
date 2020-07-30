// test/AntsReviewRoles.test.js

const { accounts, contract, web3 } = require('@openzeppelin/test-environment');

const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

const { expect } = require('chai');

const ANTS = contract.fromArtifact('ANTS')
const AntsReview = contract.fromArtifact('AntsReview');

let antsreview;

describe('AntsReview', function () {
const [ owner, issuer, peer_reviewer, approver, other, issuer1, issuer2 ] = accounts;


const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';

const issuers = [issuer, issuer1, issuer2];
const paperHash = "QmaozNR7DZHQK1ZcU9p7QdrshMvXqWK6gpu5rmrkPdT3L4";
const requirementsHash = "QmW2WQi7j6c7UgJTarActp7tDNikE4B2qXtFCfLPdsgaTQ";
var date = new Date();
const timestamp = date.getTime();
const deadline = new BN(timestamp + 31556926); // 1 year in seconds (365.24 days)
//console.log(timestamp)
const antId = "0";
const reviewId = "0";


  beforeEach(async function () {
    ants = await ANTS.new();
    antsreview= await AntsReview.new(ants.address, { from: owner });
  });

  it('the deployer is the owner', async function () {
    expect(await antsreview.owner()).to.equal(owner);
  });

  // Check issueAntReview() for success when an issuer is issuing a new AntReview
  // Check issueAntReview() for sucessfully emit event when the AntReview is Issued
  // Check issueAntReview() for failure when a random address try to issue an AntReview
  describe("issueAntReview()", async () => {

    it("issuers should be able to issue a new AntReview", async function () {
      await antsreview.addIssuer(issuer, {from: owner});
      await antsreview.issueAntReview(issuers, approver, paperHash, requirementsHash, deadline, {from: issuer});
      const receipt = await antsreview.antreviews(antId, {from: other});
      expect(receipt[0]).to.equal(paperHash);
      expect(receipt[1]).to.equal(requirementsHash);
      expect(await antsreview.getApprover(antId, {from: other})).to.equal(approver);

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

})

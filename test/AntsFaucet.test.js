// test/AntsFaucet.test.js

const { accounts, contract, web3 } = require('@openzeppelin/test-environment');

const { constants, expectEvent, expectRevert, ether } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;

const { expect } = require('chai');

const ANTS = contract.fromArtifact('ANTS');
const AntsFaucet = contract.fromArtifact('AntsFaucet');

let ants;
let faucet;

describe('AntsFaucet', function () {
const [ owner, other ] = accounts;
const amount = ether('100');
const balance = ether('90');



const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';
const PAUSER_ROLE = web3.utils.soliditySha3('PAUSER_ROLE');


  beforeEach(async function () {
    ants = await ANTS.new({from:owner})
    faucet = await AntsFaucet.new(ants.address, { from: owner })
  });

  it('the deployer is the owner', async function () {
    expect(await faucet.owner()).to.equal(owner);
  });

  it('owner has the default admin role', async function () {
    expect(await faucet.getRoleMemberCount(DEFAULT_ADMIN_ROLE)).to.be.bignumber.equal('1');
    expect(await faucet.getRoleMember(DEFAULT_ADMIN_ROLE, 0)).to.equal(owner);
  });

  it('owner has the pauser role', async function () {
    expect(await faucet.getRoleMemberCount(PAUSER_ROLE)).to.be.bignumber.equal('1');
    expect(await faucet.getRoleMember(PAUSER_ROLE, 0)).to.equal(owner);
  });

  describe("withdraw()", async () => {

      it("caller should be able to withdraw 1 ANTS", async () => {
        await ants.mint(faucet.address, amount, {from: owner});
        await faucet.withdraw({ from: other });
        expect(await ants.balanceOf(faucet.address)).to.be.bignumber.equal(balance);
      })

      it("should emit the appropriate event when ANTS are withdrawn", async function () {
        await ants.mint(faucet.address, amount, {from: owner});
        const receipt = await faucet.withdraw({ from: other });
        expectEvent(receipt, 'Withdrawal', { account: other });
      })

      it("should revert when insufficient balance of ANTS in the faucet", async () => {
        await expectRevert(faucet.withdraw({from:other}), 'Insufficient balance of ANTS in the faucet')
      })

  })

  describe('pausing', function () {
      it('owner can pause', async function () {
        const receipt = await faucet.pause({ from: owner });
        expectEvent(receipt, 'Paused', { account: owner });

        expect(await faucet.paused()).to.equal(true);
      });

      it('owner can unpause', async function () {
        await faucet.pause({ from: owner });

        const receipt = await faucet.unpause({ from: owner });
        expectEvent(receipt, 'Unpaused', { account: owner });

        expect(await faucet.paused()).to.equal(false);
      });

      it('other accounts cannot pause', async function () {
        await expectRevert(faucet.pause({ from: other }), 'AntsFaucet: must have pauser role to pause');
      });
  });


});

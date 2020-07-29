// test/AntsFaucet.test.js

const { accounts, contract, web3 } = require('@openzeppelin/test-environment');

const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;

const { expect } = require('chai');

const ANTS = contract.fromArtifact('ANTS');
const AntsFaucet = contract.fromArtifact('AntsFaucet');

let ants;
let faucet;

describe('AntsFaucet', function () {
const [ owner, other ] = accounts;

const amount = new BN('5000');

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


});

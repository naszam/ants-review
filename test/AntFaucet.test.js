// test/AntFaucet.test.js
let catchRevert = require("./exceptionsHelpers.js").catchRevert
var Ant = artifacts.require('./Ant')
var AntFaucet = artifacts.require('./AntFaucet')


contract('AntFaucet', function(accounts) {

  const owner = accounts[0]

  let ant
  let faucet

  // Before Each
  beforeEach(async () => {
    ant = await Ant.new()
    faucet = await AntFaucet.new(Ant.address)
  })

  // Check that the owner is set as the deploying address
  describe("Setup", async() => {

      it("OWNER should be set to the deploying address", async() => {
          const ownerAddress = await faucet.owner()
          assert.equal(ownerAddress, owner, "the deploying address should be the owner")
      })

  })


});

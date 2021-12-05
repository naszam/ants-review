import hre from "hardhat"
import { ANTS__factory, AntsFaucet__factory, AntsReview__factory } from "../typechain"
import { Signer } from "@ethersproject/abstract-signer"
import fs from "fs"

const { ethers } = hre

async function main() {
  const network = hre.network.name

  await hre.run("compile")

  let deployer: Signer
  if (network === "localhost") {
    // Localhost
    console.log("Deploying MakerBadges on localhost...")
    // Set deployer
    const signers: Signer[] = await ethers.getSigners()
    deployer = signers[0]
  } else {
    const signers: Signer[] = await ethers.getSigners()
    deployer = signers[0]
    const deployerAddress = await deployer.getAddress()
    if (deployerAddress !== process.env.DEPLOYER_ADDRESS) {
      throw new Error("Wrong deployer address!")
    }
  }

  // Deploy ANTS
  const ANTS: ANTS__factory = await ethers.getContractFactory("ANTS");
  const ants = await ANTS.deploy();
  await ants.deployed();

  // Deploy AntsFaucet
  const AntsFaucet: AntsFaucet__factory = await ethers.getContractFactory("AntsFaucet");
  const antsfaucet = await AntsFaucet.deploy(ants.address);
  await antsfaucet.deployed();
 
  // Deploy AntsReview
  const AntsReview: AntsReview__factory = await ethers.getContractFactory("AntsReview");
  const antsreview = await AntsReview.deploy(ants.address);
  await antsreview.deployed();

  fs.writeFileSync(
    "deploy.json",
    JSON.stringify(
      {
        ANTS: ants.address,
        AntsFaucet: antsfaucet.address,
	AntsReview: antsreview.address,
      },
      null,
      2,
    ),
  )
  console.log(`ANTS: ${ants.address}\nAntsFaucet: ${antsfaucet.address}\nAntsReview: ${antsreview.address}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});



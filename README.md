![#ubuntu 18.04](https://img.shields.io/badge/ubuntu-v18.04-orange?style=plastic)](https://ubuntu.com/download/desktop)
[![#npm 12.16.2](https://img.shields.io/badge/npm-v12.16.2-blue?style=plastic)](https://github.com/nvm-sh/nvm#installation-and-update)
[![#built_with_Truffle](https://img.shields.io/badge/built%20with-Truffle-blueviolet?style=plastic)](https://www.trufflesuite.com/)
[![#solc ^0.6.0](https://img.shields.io/badge/solc-^0.6.0-brown?style=plastic)](https://github.com/ethereum/solidity/releases/tag/^0.6.0)
[![#testnet rinkeby](https://img.shields.io/badge/testnet-Rinkeby-yellow?style=plastic&logo=Ethereum)]()


# Ants-Review
> ETHTurin 2020 Hackathon project (team 2: MetaBounty)

The Projects implements a basic Bounty-like contracts called AntsReview to allow anyone to issue an antReview in ETH, a bounty for peer-review in scientific publication, linked to requirements stored in ipfs which anyone can fufill by submitting the ipfs hash which contains evidence of their fufillment.

Project Setup
============

Clone this GitHub repository.

# Steps to compile and deploy

  - Global dependencies
    - Truffle:
    ```sh
    $ npm install -g truffle
    ```
    - Ganache:
    ```sh
    $ npm install -g ganache-cli
    ```
    - OpenZeppelin Contracts v3.0:
    ```sh
    $ npm install -g @openzeppelin/contracts@3.0.0
    ```
    - MythX for Truffle (optional):
    ```sh
    $ npm install -g truffle-security
    ```
## Running the project with local test network (ganache-cli)

   - Start ganache-cli with the following command:
     ```sh
     $ ganache-cli
     ```
   - Compile the smart contract using Truffle with the following command:
     ```sh
     $ truffle compile
     ```
   - Deploy the smart contracts using Truffle & Ganache with the following command:
     ```sh
     $ truffle migrate
     ```
   - Test the smart contracts using Truffle & Ganache with the following command:
     ```sh
     $ truffle test
     ```
   - Analyze the smart contracts using MythX for Truffle with the following command (optional):
     ```sh
     $ truffle run verify
     ```
## Deploying on Rinkeby's Testnet
  - Get an Ethereum Account on Metamask.
  - On the landing page, click “Get Chrome Extension.”
  - Create a .secret file cointaining the menomic.
  - Get some test ether from a [Rinkeby's faucet](https://faucet.rinkeby.io/).
  - Signup [Infura](https://infura.io/).
  - Create new project.
  - Copy the rinkeby URL into truffle-config.js.
  - Uncomment the following lines in truffle-config.js:
    ```
    // const HDWalletProvider = require("@truffle/hdwallet-provider");
    // const infuraKey = '...';
    // const infuraURL = 'https://rinkeby.infura.io/...';

    // const fs = require('fs');
    // const mnemonic = fs.readFileSync(".secret").toString().trim();
    ```
  - Install Truffle HD Wallet Provider:
    ```sh
    $ npm install @truffle/hdwallet-provider
    ```
  - Deploy the smart contract using Truffle & Infura with the following command:
    ```sh
    $ truffle migrate --network rinkeby
    ```
    
    
## Inspiration & References
- [oscoin](http://oscoin.io/oscoin.pdf)
- [Towards Open Science: The Case for a Decentralized Autonomous Academic Endorsement System](https://zenodo.org/record/60054#.XqMYqnVKg5k)
- [ERC20](https://eips.ethereum.org/EIPS/eip-20)
- [Bounties-Network](https://www.bounties.network/)
- [Gitcion](gitcoin.co)
- [IPFS](https://ipfs.io/)
- [ZKPs](https://people.csail.mit.edu/silvio/Selected%20Scientific%20Papers/Zero%20Knowledge/Noninteractive_Zero-Knowkedge.pdf)
- [AZTEC Protocol](https://www.aztecprotocol.com/)

## About

Project created by [Nazzareno Massari](http://nazzarenomassari.com) and [Bianca Trovò](https://github.com/biancasama)

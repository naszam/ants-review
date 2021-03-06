import React, { Component } from "react";
import Logo from "./logo.svg";
import AntsReview from "./contracts/AntsReview.json";
import getWeb3 from "./getWeb3";

import "./App.css";

import 'react-bootstrap-table/dist/react-bootstrap-table-all.min.css';


import { Text, Button, Card, Box, Flex, Form, Input, Heading, Field} from 'rimble-ui';

import BootstrapTable from 'react-bootstrap-table/lib/BootstrapTable';
import TableHeaderColumn from 'react-bootstrap-table/lib/TableHeaderColumn';


import NetworkIndicator from "@rimble/network-indicator";

const etherscanBaseUrl = "https://rinkeby.etherscan.io"

class App extends Component {
  constructor(props) {
    super(props)

    this.state = {
      etherscanLink: "https://rinkeby.etherscan.io",
      web3: null,
      accounts: null,
      antsReviewInstance: null,
      antreviews: [],
      dataToAdd: undefined,
      deadlineToAdd: undefined,
      antReviewValue: undefined,
      antId: undefined,
      peerHash: undefined,
      antId2: undefined,
      peerId: undefined,
      antId3: undefined,
    };
    this.handleIssueAntReview = this.handleIssueAntReview.bind(this)
    this.handleFulfillAntReview = this.handleFulfillAntReview.bind(this)
    this.handleAcceptAntReview = this.handleAcceptAntReview.bind(this)
    this.handleCancelAntReview = this.handleCancelAntReview.bind(this)
    this.handleChange = this.handleChange.bind(this)


  }

  componentDidMount = async () => {
    try {
      // Get network provider and web3 instance.
      const web3 = await getWeb3();

      // Use web3 to get the user's accounts.
      const accounts = await web3.eth.getAccounts();

      // Get the contract instance.
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = AntsReview.networks[networkId];
      const instance = new web3.eth.Contract(
        AntsReview.abi,
        deployedNetwork && deployedNetwork.address,
      );

      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
      this.setState({ networkId: networkId, web3: web3, accounts: accounts[0], antsReviewInstance: instance });
      this.listenAntReviewIssuedEvent(this)

    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`,
      );
      console.error(error);
    }
  };

  listenAntReviewIssuedEvent=(component) => {

      this.state.antsReviewInstance.events.AntReviewIssued({fromBlock: 0})
      .on('data', async (event) => {

        var newAntReviewArray = component.state.antreviews.slice()
        newAntReviewArray.push(event.returnValues)
        component.setState({ antreviews: newAntReviewArray })

      })
      .on('error', console.error);
  }

  handleIssueAntReview = async (event) => {
  if (typeof this.state.antsReviewInstance !== 'undefined') {
    event.preventDefault()
  // Get the value from the contract to prove it worked.
  let result = await this.state.antsReviewInstance.methods.issueAntReview(this.state.dataToAdd, this.state.deadlineToAdd).send({from: this.state.accounts, value: this.state.web3.utils.toWei(this.state.antReviewValue, 'ether')});
  //const response = await this.state.storesInstance.methods.isAdmin(this.state.adminAddressToAdd).call();
  // Update state with the result.
  this.setLastTransactionDetails(result)
  }
}

  handleFulfillAntReview = async (event) => {
  if (typeof this.state.antsReviewInstance !== 'undefined') {
    event.preventDefault()
  // Get the value from the contract to prove it worked.
  let result = await this.state.antsReviewInstance.methods.fulfillAntReview(this.state.antId, this.state.peerHash).send({from: this.state.accounts});

  // Update state with the result.
  this.setLastTransactionDetails(result)
  }
}

  handleAcceptAntReview = async (event) => {
  if (typeof this.state.antsReviewInstance !== 'undefined') {
      event.preventDefault()
  // Get the value from the contract to prove it worked.
  let result = await this.state.antsReviewInstance.methods.acceptFulfillment(this.state.antId2, this.state.peerId).send({from: this.state.accounts});

  // Update state with the result.
  this.setLastTransactionDetails(result)
  }
}

  handleCancelAntReview = async (event) => {
  if (typeof this.state.antsReviewInstance !== 'undefined') {
     event.preventDefault()
  // Get the value from the contract to prove it worked.
  let result = await this.state.antsReviewInstance.methods.cancelAntReview(this.state.antId3).send({from: this.state.accounts});
  console.log(result)
  // Update state with the result.
  this.setLastTransactionDetails(result)
  }
}

handleChange(event)
  {
    switch(event.target.name) {
        case "addHash":
            this.setState({ dataToAdd: event.target.value})
            break;
        case "addDeadline":
            this.setState({ deadlineToAdd: event.target.value})
            break;
        case "addAntReviewValue":
            this.setState({ antReviewValue: event.target.value})
            break;
        case "addId":
            this.setState({ antId: event.target.value})
            break;
        case "addPeerHash":
            this.setState({ peerHash: event.target.value})
            break;
        case "addId2":
            this.setState({ antId2: event.target.value})
            break;
        case "addPeerId":
            this.setState({ peerId: event.target.value})
            break;
        case "addId3":
            this.setState({ antId3: event.target.value})
            break;
        default:
            break;
      }
  }

  setLastTransactionDetails(result)
  {
    if(result.tx !== 'undefined')
    {
      this.setState({etherscanLink: etherscanBaseUrl+"/tx/"+result.tx})
    }
    else
    {
      this.setState({etherscanLink: etherscanBaseUrl})
    }
  }

  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div className="App">
      <a href={this.state.etherscanLink} target="_blank" rel="noopener noreferrer">Last Transaction Details</a>
      <Card maxWidth={'320px'} mx={'auto'} p={3} px={4}>
        <NetworkIndicator
          currentNetwork={this.state.networkId}
          requiredNetwork={4}
        />
      </Card>
      <Heading as={"h4"}> Current Ethereum Address: {this.state.accounts} </Heading>
      <Box>
      <img src={Logo} width="100" height="100" alt="Ants-Review Logo"/>
      <Heading as={"h1"}> Ants-Review </Heading>
      <Text> A Protocol for Open Anonymous Scientific Peer-Reviews on Ethereum </Text>
      </Box>
      <Flex>
      <Box p={3} width={1 / 2}>
      <Heading> Issue AntReview </Heading>
      <Form>
        <Box>
          <Field label="IPFS Hash">
            <Input
              type="text"
              placeholder="e.g. QmW2WQi7j6c7UgJTarActp7tDNikE4B2qXtFCfLPdsgaTQ"
              required="true"
              name="addHash"
              value={this.state.dataToAdd}
              onChange={this.handleChange} />
          </Field>
          <Field label="Deadline">
            <Input
            type="text"
            placeholder="timestamp"
            required="true"
            name="addDeadline"
            value={this.state.deadlineToAdd}
            onChange={this.handleChange} />
            </Field>
            <Field label="Ether">
              <Input
              type="text"
              placeholder="ether"
              required="true"
              name="addAntReviewValue"
              value={this.state.antReviewValue}
              onChange={this.handleChange} />
              </Field>
        </Box>
      <Box>
      <Button value="Submit" onClick={this.handleIssueAntReview} >Issue AntReview</Button>
      </Box>
      </Form>
      </Box>
      <Box p={3} width={1 / 2}>
      <Heading> Fulfill AntReview </Heading>
      <Form>
        <Box>
          <Field label="AntReview Id">
            <Input
              type="text"
              placeholder="e.g. 0"
              required="true"
              name="addId"
              value={this.state.antId}
              onChange={this.handleChange} />
          </Field>
          <Field label="Peer-Review IPFS Hash">
            <Input
            type="text"
            placeholder="e.g. QmW2WQi7j6c7UgJTarActp7tDNikE4B2qXtFCfLPdsgaTQ"
            required="true"
            name="addPeerHash"
            value={this.state.peerHash}
            onChange={this.handleChange} />
            </Field>
        </Box>
      <Box>
      <Button value="Submit" onClick={this.handleFulfillAntReview} >Fulfill AntReview</Button>
      </Box>
      </Form>
      </Box>
      </Flex>
      <Flex>
      <Box p={3} width={1 / 2}>
      <Heading> Cancel AntsReview </Heading>
      <Form>
        <Box>
          <Field label="AntReview Id">
            <Input
              type="text"
              placeholder="e.g. 0"
              required="true"
              name="addId3"
              value={this.state.antId3}
              onChange={this.handleChange} />
          </Field>
        </Box>
      <Box>
      <Button value="Submit" onClick={this.handleCancelAntReview} > Cancel AntsReview </Button>
      </Box>
      </Form>
      </Box>
      <Box p={3} width={1 / 2}>
      <Heading> Accept Fulfillment </Heading>
      <Form>
        <Box>
          <Field label="AntReview Id">
            <Input
              type="text"
              placeholder="e.g. 0"
              required="true"
              name="addId2"
              value={this.state.antId2}
              onChange={this.handleChange} />
          </Field>
          <Field label="Peer-Review Id">
            <Input
            type="text"
            placeholder="e.g. 0"
            required="true"
            name="addPeerId"
            value={this.state.peerId}
            onChange={this.handleChange} />
            </Field>
        </Box>
      <Box>
      <Button value="Submit" onClick={this.handleAcceptAntReview} > Accept Fulfillment </Button>
      </Box>
      </Form>
      </Box>
      </Flex>
      <Flex>
      <Box width={1}>
      <Heading> Issued AntReviews </Heading>
      <Form>
       <BootstrapTable data={this.state.antreviews} striped hover>
      <TableHeaderColumn isKey dataField='antReview_id'>ID</TableHeaderColumn>
      <TableHeaderColumn dataField='issuer'>Issuer</TableHeaderColumn>
      <TableHeaderColumn dataField='amount'>Amount (Wei)</TableHeaderColumn>
      <TableHeaderColumn dataField='data'>IPFS Hash</TableHeaderColumn>
       </BootstrapTable>
      </Form>
      </Box>
      </Flex>
      </div>
    );
  }
}
export default App;

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

contract Crowdfunding {
    mapping(address => uint) public contributors;
    address public admin; // person handling the funds
    uint public numOfContributors; 
    uint public minContribution;
    uint public deadline; // timestamp of deadline
    uint public goal; // amount to raise
    uint public raisedAmount;

    struct Request { // a spending request the admin has to submit before contributors vote on it
        string description;
        address payable recipient;
        uint value;
        uint numOfVoters;
        bool completed;
        mapping(address => bool) voters;
    }

    // currently, dynamic storage arrays cannot get assigned data containing mappings, which is 
    // why we need this variable in place of an array.
    mapping(uint => Request) public requests;
    uint public numRequests; 

    constructor(uint _goal, uint _deadline) {
        goal = _goal;
        deadline = block.timestamp + _deadline;
        minContribution = 100 wei;
        admin = msg.sender;
    }

    receive() payable external { // contributions sent directly to the contract will be counted
        contribute();
    }

    event Contributed(address _sender, uint _value); // a donor contributed
    event RequestCreated(string _description, address _recipient, uint _value); // a spending request was made
    event PaymentMade(address _recipient, uint value); // a payment was made to a recipient using contributions

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin call call this function.");
        _;
    }

    // The admin uses this function to create a spending request
    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.numOfVoters = 0;
        // By default, the mapping voters will initially map any address sent to it as false

        emit RequestCreated(_description, _recipient, _value);
    }

    function voteRequest(uint _requestNum) public { // contributors call this to vote on whether to approve a spending request
        require(contributors[msg.sender] > 0, "You must be a contributor to vote!");
        Request storage thisRequest = requests[_requestNum];
        
        require(thisRequest.voters[msg.sender] == false, "You have already voted!");
        thisRequest.numOfVoters++;
    }

    // The admin will use this function to send funds for approved spending requests
    function makePayment(uint _requestNum) public onlyAdmin {
        require(raisedAmount >= goal, "The goal hasn't been met yet.");
        Request storage thisRequest = requests[_requestNum];
        require(thisRequest.completed == false, "The request has been completed!");
        require(thisRequest.numOfVoters > numOfContributors / 2); // 50% majority vote

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;

        emit PaymentMade(thisRequest.recipient, thisRequest.value);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function contribute() public payable {
        require(block.timestamp < deadline, "The deadline has passed.");
        require(msg.value >= minContribution, "The minimum contribution needs to be met.");

        if(contributors[msg.sender] == 0) {
            numOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;

        emit Contributed(msg.sender, msg.value);
    }

    function getRefund() public {
        require(block.timestamp > deadline && raisedAmount < goal, "Refunds are only allowed when the goal hasn't been reached by the deadline.");
        require(contributors[msg.sender] > 0, "Must be a contributor.");

        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        recipient.transfer(value);

        // payable(msg.sender).transfer(contributors[msg.sender]);

        contributors[msg.sender] = 0;
    }
}
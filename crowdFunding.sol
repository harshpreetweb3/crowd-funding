// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding{
    
    mapping(address=>uint) public contributors;
    address public manager;
    uint public target;
    uint public deadline;
    uint public raisedAmount;
    uint public noOfContributors;
    uint public minimumContribution;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        uint noOfVoters;
        bool completed;
        mapping(address=>bool) voters;
    }

    mapping(uint=>Request) public requests;
    uint public numRequests; //0 

    constructor (uint _target, uint _deadline){
        target=_target;
        deadline=block.timestamp+_deadline;
        minimumContribution=100 wei;
        manager=msg.sender;
    }

    function sendEth() public payable{
        require(block.timestamp< deadline, "Deadline has been passed");
        require(msg.value>= minimumContribution, "minimumContribution is not met");

        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+= msg.value;
        raisedAmount+= msg.value;

    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public {
        require(raisedAmount<= target && deadline>block.timestamp, "You are not eligible for refund");
        /* require(msg.sender== contributors[msg.sender]) */
        require(contributors[msg.sender]>0, "You are not a contributor");
        address payable user= payable(msg.sender);
        user.transfer(contributors[msg.sender]);
    }

    modifier onlyManager(){
        require(msg.sender==manager,"Only manager can call this function");
        _;
    }

    function createRequests(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest= requests[numRequests];
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.noOfVoters=0;
    }

    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0, "You are not a Contributor");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true; 
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount>=target, "Payment cannot be made as Targeted funds are not raised");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed==false,"Request has already been completed");
        require(thisRequest.noOfVoters >=noOfContributors/2,"Majority doesn't supports");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
}

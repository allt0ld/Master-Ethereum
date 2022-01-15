//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract AuctionCreator {
    Auction[] public auctions;

    function createAuction() public {
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

contract Auction {
    address payable public owner;
    // use the block number to track time (1 block every ~15 s) 
    // can't be spoofed unlike block.timestamp
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash; //ipfs hash to save gas by storing related media (i.e. pictures) off-chain using IPFS

    //all possible auction states
    enum State {Running,  
                Ended, 
                Canceled} 
    State public auctionState;

    uint public highestBindingBid; // the price the auction winner will pay
    address payable public highestBidder;

    mapping(address => uint) public bids;

    uint bidIncrement; // minimum amount that users can increment their bids by on top of the highest binding bid

    constructor(address eoa) {
        owner = payable(eoa);
        auctionState = State.Running;
        startBlock = block.number; 
        endBlock = startBlock + 40320; // roughly 40320 blocks in a week
        ipfsHash = "";
        bidIncrement = 0.1 ether;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier notOwner() { // the owner can't place bids on the auction to inflate the price
        require(msg.sender != owner, "Stop trying to bid on your own auction, doofus.");
        _;
    }

    modifier afterStart() { // makes sure we have started the auction 
        require(block.number >= startBlock, "The auction hasn't started yet.");
        _;
    }

    modifier beforeEnd() { // makes sure the auction hasn't ended yet
        if(block.number > endBlock && auctionState == State.Running) {
            auctionState = State.Ended;
        }
        require(block.number <= endBlock, "The auction has already ended.");
        _;
    }

    function min(uint a, uint b) pure internal returns (uint) {
        if(a < b) {
            return a;
        } else {
            return b; 
        }
    }

    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }

    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running, "The auction is not in progress.");
        require(msg.value >= bidIncrement, string(abi.encodePacked("Must increment bid by at least the minimum amount ", bidIncrement))); 

        uint currentBid = bids[msg.sender] + msg.value; //if the user hasn't bid before, bids[msg.sender] will be 0 by default
        require(currentBid > highestBindingBid, 
                string(abi.encodePacked("Total bid must be greater than the highest binding bid ", highestBindingBid, " wei.")));
        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]) {
            // every bid <= the highest bid increases the binding bid to the lower of the highest bid 
            // or the currentBid incremented by bidIncrement
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]); 
        } else {
            // every bid > the highest bid makes the lower of currentBid or the highest bid incremented 
            // by bidIncrement the binding bid
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender); // update the highest bidder
        }
    }

    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock); 
        // the auction ends when it's canceled or when time runs out
        require(msg.sender == owner || bids[msg.sender] > 0); //either the owner or a bidder can finalize the auction

        address payable recipient;
        uint value;

        if(auctionState == State.Canceled) { //auction was canceled
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            auctionState = State.Ended;
            if(msg.sender == owner) { 
            // when the owner calls this function, they are the recipient of the highest binding bid
                recipient = owner;
                value = highestBindingBid;
            } else { // this is a bidder
                if(msg.sender == highestBidder) {
                    recipient = highestBidder;
                    // the highest bidder is refunded the spread between their highest bid and the binding bid
                    value = bids[highestBidder] - highestBindingBid; 
                } else { // this is neither the owner nor the highest bidder
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }

                // we reset the bid value only if we know the user is a bidder who hasn't reclaimed
                // their bid, which saves gas by avoiding unnecessary writes in the case of the owner. 
                bids[recipient] = 0;
            }
        }

        recipient.transfer(value);

    }
}
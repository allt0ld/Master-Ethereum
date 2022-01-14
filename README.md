# Master-Ethereum
 Some Projects Using Solidity

 Thanks to Andrei and Crystal Mind Academy for providing this course: https://www.udemy.com/course/master-ethereum-and-solidity-programming-with-real-world-apps/ 

 ## Projects:

 ### Project 1: Lottery
 An externally owned account can deploy this contract and manage an on-chain lottery, where users can transfer ETH from their wallets directly to the contract, adding to a pool of money. A random number gets generated by hashing the block difficulty, the block timestamp, and the number of users in the lottery (nonce); then, when there are enough players, a winner is selected by taking the remainder of the random number divided by n, where n is the number of players. I don't use a secure random number generating algorithm since this is more of a learning project. The manager takes a 10% cut of the winnings. 

 ### Project 2: Auction
 This project required a lot more effort. A user who presumably wants to auction off one of their possessions can deploy this contract (a storage array tracks all auctions created by users using the AuctionCreator contract) and have others bid on the item. The auction ends when a given number of blocks have been mined since the start. Bidders have to bid in or in excess of a defined increment, where the highest bidder has to pay the binding bid, which is up to one incremental unit more than the second highest bid. If the auction is successful, the highest bidder gets the item for the binding bid price. The auction can either be canceled or finished after time runs out. In either case, users who didn't win the auction have to manually request that their funds be returned in order to prevent hacks, such as the DAO hack, where contracts run malicious receive() or fallback() functions.

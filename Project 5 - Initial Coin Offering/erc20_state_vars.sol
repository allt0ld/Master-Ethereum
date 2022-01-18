//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

interface ERC20Interface {
    // Pulled from OpenZeppelin's implementation:
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/9b3710465583284b8c4c5d2245749246bb2e0094/contracts/token/ERC20/IERC20.sol
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Cryptos is ERC20Interface {
    string public name = "Cryptos";
    string public symbol = "CRPT";
    uint public decimals = 0; //18 is used for ETH, denotes divisibility of token
    uint public override totalSupply;

    address public founder;
    mapping(address => uint) public balances;
    // mapping token holder addresses to mappings of other accounts allowed to withdraw a given amount of tokens 
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply; // founder is given the whole supply at the start
    }

    function balanceOf(address tokenOwner) public view override returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens) public virtual override returns (bool success) {
        require(balances[msg.sender] >= tokens);
        balances[to] += tokens;
        balances[msg.sender] -= tokens; 
        emit Transfer(msg.sender, to, tokens);

        return true; // function reverts if the transfer fails, returns true if the transfer succeeds
    }

    function allowance(address tokenOwner, address spender) view public override returns(uint) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);

        allowed[msg.sender][spender] += tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public virtual override returns (bool success) {
        require(allowed[to][from] >= tokens);
        require(balances[from] >= tokens);

        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][to] -= tokens;
        emit Transfer(from, to, tokens);

        return true;
    }
}

contract CryptosICO is Cryptos {
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.001 ether; // inital rate of 1 ETH = 1000 CRPT, 1 CRPT = 0.001 ETH
    uint public hardCap = 300 ether; // total possible investment
    uint public raisedAmount;
    uint public saleStart = block.timestamp; // ICO starts immediately from deployment
    uint public saleEnd = block.timestamp + 604800; // ICO ends in one week
    uint public tokenTradeStart = saleEnd + 604800; // tokens are locked up for one week; then they become available to trade
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.1 ether;

    enum State {beforeStart, running, afterEnd, halted}
    State public icoState;

    event Invest(address investor, uint value, uint tokens);

    constructor(address payable _deposit) {
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }

    receive() payable external {
        invest();
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    // halt the offering
    function halt() public onlyAdmin {
        icoState = State.halted;
    }

    // resume the offering
    function resume() public onlyAdmin {
        icoState = State.running;
    }

    // change the deposit location if the current one is compromised
    function changeDepositAddress(address payable newDeposit) public onlyAdmin {
        deposit = newDeposit;
    }

    function getCurrentState() public view returns (State) {
        if(icoState == State.halted) {
            return State.halted;
        } else if(block.timestamp < saleStart) {
            return State.beforeStart;
        } else if (block.timestamp >= saleStart && block.timestamp <= saleEnd) {
            return State.running;
        } else {
            return State.afterEnd;
        }
    }

    function invest() payable public returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.running, "The ICO is not currently running.");
        require(msg.value >= minInvestment && msg.value <= maxInvestment, "Your investment is either too large or too small.");
        raisedAmount += msg.value;
        require(raisedAmount <= hardCap, "The investment cap has been met.");

        uint tokens = msg.value / tokenPrice;

        balances[msg.sender] += tokens;
        balances[founder] -= tokens; // since at first the founder holds all the CRPT
        deposit.transfer(msg.value);

        emit Invest(msg.sender, msg.value, tokens);

        return true;
    }

    function transfer(address to, uint256 tokens) public override returns (bool success) {
        require(block.timestamp > tokenTradeStart);
        super.transfer(to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success) {
        require(block.timestamp > tokenTradeStart);
        super.transferFrom(from, to, tokens);
        return true;
    }

    // this function burns any remaining tokens in the founder's wallet after the sale is over.
    function burn() public returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
    }
}
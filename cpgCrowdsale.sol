pragma solidity ^0.4.15;

interface cpgtoken {
    function getTotalSupply() constant public returns(uint256);
    function transfer(address receiver, uint amount);
    function burn(uint256 _value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract CPGTokenCrowdSale is Ownable {
  using SafeMath for uint256;

  struct TimeBonus {
    uint256 bonusPeriodEndTime;
    uint bonusPercent;
    uint tokenPercent;
    bool applyKYC;
  }

  /* The token object */
  cpgtoken public token;

  /* Start and end timestamps where investments are allowed (both inclusive) */
  uint256 public mainSaleStartTime;
  uint256 public mainSaleEndTime;

  /* Address where funds are transferref after collection */
  address public projectWallet;

  /* Address where final 30% of funds will be collected */
  address public reserveWallet;

  /* How many token units a buyer gets per ether */
  uint256 public rate = 1000;

  /* Amount of selled cpg */
  uint256 public cpgSelled;
  uint256 public amountRaised;

  /* Amount of total selling cpg*/
  uint256 public sellSupply;

  /* Minimum amount of Wei allowed per transaction = 0.1 Ethers */
  uint256 public saleMinimumWei = 100000000000000000; 

  TimeBonus[] public timeBonuses;

  bool isKYC = true;
  mapping(address => bool) KYCaddrs;

  uint256 public softWeiCap;
  uint256 public hardWeiCap;

  bool fundingGoalReached = false;
  bool crowdsaleClosed = false;
  mapping(address => uint256) public balanceOf; //每个投资人投了多少Wei

  /**
   * event for token purchase logging
   * event for finalizing the crowdsale
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event GoalReached(address recipient, uint totalAmountRaised);
  event FundTransfer(address backer, uint amount, bool isContribution);
  // event FinalisedCrowdsale(uint256 totalSupply, uint256 reserveTokens);

  function CPGTokenCrowdSale(uint256 _mainSaleStartTime, address _projectWallet, address _reserveWallet, address addressOfTokenUsedAsReward, uint256 _softEthCap, uint256 _hardEthCap) public {

    /* Can't start main sale in the past */
    require(_mainSaleStartTime >= now);

    /* Confirming projectWaddresses as valid */
    require(_projectWallet != 0x0);
    require(_reserveWallet != 0x0);

    /* The Crowdsale bonus pattern
     * 1 day = 86400 = 60 * 60 * 24 (Seconds * Minutes * Hours)
     * 1 day * Number of days to close at, Bonus Percentage, selling tokens percentage, enabled kyc
     */
  
    timeBonuses.push(TimeBonus(86400*3,   30,   30,   true)); // 0 - 3 Days, 30 %, 30% selling tokens
    timeBonuses.push(TimeBonus(86400*7,   20,   50,   true)); // 3 -7 Days, 20 %, 30%+20% selling tokens
    timeBonuses.push(TimeBonus(86400*14,  15,   60,   false)); // 7-14 Days, 15 %, 50%+10% selling tokens
    timeBonuses.push(TimeBonus(86400*21,  10,   70,   false)); // 14-21 Days, 10  %, 60%+10% selling tokens
    timeBonuses.push(TimeBonus(86400*28,  5,    80,   false)); // 21-28 Days, 5  %, 70%+10% selling tokens
    timeBonuses.push(TimeBonus(86400*35,  0,    100,  false)); // 28-35 Days, 0  %, 80%+20% selling tokens

    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = mainSaleStartTime + 35 days;
    projectWallet = _projectWallet;
    reserveWallet = _reserveWallet;
    softWeiCap = _softEthCap * 1 ether;
    hardWeiCap = _hardEthCap * 1 ether;

    token = cpgtoken(addressOfTokenUsedAsReward);
    uint256 total = token.getTotalSupply();
    uint256 reserveTokens = total.mul(30).div(100);
    token.transfer(reserveWallet, reserveTokens);
    sellSupply = total.mul(70).div(100);

  }

  // /* Creates the token to be sold */
  // function createTokenContract() internal returns (MintableToken) {
  //   return new CPGToken();
  // }

  /* Fallback function can be used to buy tokens */
  function () payable {
    buyTokens(msg.sender);
  }

  /* Low level token purchase function */
  function buyTokens(address beneficiary) public payable {
    require(!crowdsaleClosed);
    require(beneficiary != 0x0);
    require(msg.value != 0);
    require(now <= mainSaleEndTime && now >= mainSaleStartTime);
    require(msg.value >= saleMinimumWei);
    require(isKYC && validKYCAddr(beneficiary));
    require(amountRaised <= hardWeiCap);

    /* Add bonus to tokens depends on the period */
    uint256 bonusedTokens = applyBonus(msg.value);

    /* Update state on the blockchain */
    cpgSelled = cpgSelled.add(bonusedTokens);
    amountRaised = amountRaised.add(msg.value);
    balanceOf[msg.sender].add(msg.value);

    token.transfer(beneficiary, bonusedTokens);
    TokenPurchase(msg.sender, beneficiary, msg.value, bonusedTokens);

  }

  function setKYCstatus(bool status) internal {
    if (isKYC != status) {
      isKYC = status;
    }
  }

  function addKYCAddr(address addr) external onlyOwner returns(bool) {
    KYCaddrs[addr] = true;
  }

  function removeKYCAddr(address addr) external onlyOwner returns(bool) {
    KYCaddrs[addr] = false;
  }

  function validKYCAddr(address addr) internal returns(bool) {
    return KYCaddrs[addr];
  }

  modifier afterDeadline() {
    require(now >= mainSaleEndTime);
    _;
  }

  /**
    * Check if goal was reached
    *
    * Checks if the goal or time limit has been reached and ends the campaign
    */
  function checkGoalReached() afterDeadline {
      if (amountRaised >= softWeiCap) {
          fundingGoalReached = true;
          GoalReached(projectWallet, amountRaised);
      }
      crowdsaleClosed = true;
  }

    /**
    * Withdraw the funds
    *
    * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
    * sends the entire amount to the projectWallet. If goal was not reached, each contributor can withdraw
    * the amount they contributed.
    */
  function safeWithdrawal() afterDeadline {
      if (!fundingGoalReached) {
          uint256 amount = balanceOf[msg.sender];
          balanceOf[msg.sender] = 0;
          if (amount > 0) {
              if (msg.sender.send(amount)) {
                  FundTransfer(msg.sender, amount, false);
              } else {
                  balanceOf[msg.sender] = amount;
              }
          }
      }

      if (fundingGoalReached && projectWallet == msg.sender) {
          if (projectWallet.send(this.balance)) {
              FundTransfer(projectWallet, amountRaised, false);
          } else {
              //If we fail to send the funds to projectWallet, unlock funders balance
              fundingGoalReached = false;
          }
      }
  }

  /* Set new dates for main-sale (emergency case) */
  function setMainSaleDates(uint256 _mainSaleStartTime, uint256 _mainSaleEndTime) public onlyOwner returns (bool) {
    require(!crowdsaleClosed);
    require(now <= mainSaleEndTime && now >= mainSaleStartTime);
    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = _mainSaleEndTime;
    return true;
  }

  function burn(uint256 _value) public onlyOwner {
    token.burn(_value);
  }
  
  /* Send ether to the fund collection projectWallet*/
  function forwardFunds() internal {
    projectWallet.transfer(this.balance);
  }

  /* Function to calculate bonus tokens based on current time(now) and maximum tokenscap per tier */
  function applyBonus(uint256 weiAmount) internal constant returns (uint256 bonusedTokens) {
    /* Bonus tokens to be added */
    uint256 tokensToAdd = 0;

    /* Calculting the amont of tokens to be allocated based on rate and the money transferred*/
    uint256 tokens = weiAmount.mul(rate);
    uint256 diffInSeconds = now.sub(mainSaleStartTime);

    for (uint i = 0; i < timeBonuses.length; i++) {
      /* If cap[i] is reached then skip */
      if (cpgSelled < sellSupply.mul(timeBonuses[i].tokenPercent).div(100)) {
        for (uint j = i; j < timeBonuses.length; j++) {
          /* Check which week period time it lies and use that percent */
          if (diffInSeconds <= timeBonuses[j].bonusPeriodEndTime) {
            tokensToAdd = tokens.mul(timeBonuses[j].bonusPercent).div(100);
            setKYCstatus(timeBonuses[j].applyKYC);
            return tokens.add(tokensToAdd);
          }
        }
      }
    }
    
  }

  /*  
  * Function to extract funds as required before finalizing
  */
  function fetchFunds() onlyOwner public {
    projectWallet.transfer(this.balance);
  }

}
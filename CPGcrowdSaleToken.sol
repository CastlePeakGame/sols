pragma solidity ^0.4.18;

/**
 * @title SafeMath-xxp
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
  function Ownable() public {
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

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20Basic {

  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;
  mapping(address => uint256) balances;
  // uint256 public totalSupply;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is BurnableToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

/*
 * @title CPGToken
 */
contract CPGToken is MintableToken {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 等同于Wei的概念
    // 18 decimals is the strongly suggested default, avoid changing it
    // uint256 public totalSupply;

  function CPGToken( uint256 _initialSupply, string _tokenName, string _tokenSymbol) public {
      name = _tokenName;
      symbol = _tokenSymbol;
      totalSupply = _initialSupply * 10 ** uint256(decimals);

      // Allocate initial balance to the owner
      balances[msg.sender] = totalSupply;
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
  CPGToken public token;

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

    token = CPGToken(addressOfTokenUsedAsReward);
    uint256 total = token.totalSupply();
    uint256 reserveTokens = total.mul(30).div(100);
    token.transfer(reserveWallet, reserveTokens);
    sellSupply = total.mul(70).div(100);

  }

  // /* Creates the token to be sold */
  // function createTokenContract() internal returns (MintableToken) {
  //   return new CPGToken();
  // }

  /* Fallback function can be used to buy tokens */
  function () public payable {
    buyTokens(msg.sender);
  }

  /* Low level token purchase function */
  function buyTokens(address beneficiary) public payable {
    require(!crowdsaleClosed);
    require(beneficiary != 0x0);
    require(msg.value != 0);
    require(now <= mainSaleEndTime && now >= mainSaleStartTime);
    require(msg.value >= saleMinimumWei);
    require(amountRaised <= hardWeiCap);

    /* Add bonus to tokens depends on the period */
    uint256 bonusedTokens = applyBonus(msg.value);
    if (isKYC) {
        require(validKYCAddr(beneficiary));
    }
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

  function validKYCAddr(address addr) internal view returns(bool) {
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
  function checkGoalReached() afterDeadline public {
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
  function safeWithdrawal() afterDeadline public {
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
  function applyBonus(uint256 weiAmount) internal returns (uint256 bonusedTokens) {
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
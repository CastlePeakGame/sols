pragma solidity ^0.4.18;

/**xxp 校验防止溢出情况
 * @title SafeMath
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
  // store tokens
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

contract MintableToken is StandardToken, Ownable {
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

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

/**
 * @title Pausable token
 *
 * @dev StandardToken modified with pausable transfers.
 **/

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }
}

/*
 * @title CPGToken
 */
contract CPGToken is BurnableToken, MintableToken, PausableToken {
  // Public variables of the token
  string public name;
  string public symbol;
  // 等同于Wei的概念,  decimals is the strongly suggested default, avoid changing it
  uint8 public decimals;

  // function CPGToken( uint256 _initialSupply, string _tokenName, string _tokenSymbol, uint8 _decimals) public {
  function CPGToken() public {
    name = "CPG Game";
    symbol = "CPG";
    decimals = 18;
    totalSupply = 98000000 * 10 ** uint256(decimals);

    // Allocate initial balance to the owner
    balances[msg.sender] = totalSupply;
  }
}

contract CPGCrowdSale is Ownable {
  using SafeMath for uint256;

  struct MileStone {
    string name;
    uint diffStartTime;
    // uint256 amountTokens;
    uint amountEtherRaised;
    uint minCNY;
    uint saleMinNumEther;
    uint maxCNY;
    uint saleMaxNumEther;
    uint capCNY;
    uint hardEtherCap;
  }

  /* Start and end timestamps where investments are allowed (both inclusive) */
  uint public mainSaleStartTime;
  uint public mainSaleEndTime;

  /* Address where funds are transferref after collection */
  address public fundsWallet;

  MileStone[] public mileStones;
  uint8 public currentState = 0;

  //每个投资人投了多少以太币
  mapping(address => uint256) public investedEtherAmount;

  // bool public isDistributed = false;
  uint ethPrice = 3000;

  /**
   * event for token logging
   */
  event TokenPurchase(uint timeStamp, address indexed purchaser, address indexed beneficiary, uint256 value);
  event FundTransfer(address backer, uint256 amount, bool isContribution);
  event ChangeEtherPrice(uint oldPrice, uint ethPrice);
  event ChangeSaleDates(uint mainSaleStartTime, uint mainSaleEndTime);
  // event TokenDistribute(address teamPartner, uint256 amountCPG);

  function CPGCrowdSale(uint _mainSaleStartTime, address _fundsWallet) public {
    /* Can't start main sale in the past */
    require(_mainSaleStartTime >= now);

    /* Confirming addresses as valid */
    require(_fundsWallet != 0x0);

    /* The Crowdsale pattern
     * 1 days = 86400 = 60 * 60 * 24 (Seconds * Minutes * Hours)
     * name, 距启动时间差（秒), 已收以太币, 单笔下限(cny, ether), 单笔上限(cny, ether)， 每阶段硬顶
     * privateICO has no time limit， set the max timestamp.
     */
    mileStones.push(MileStone("private", 1 hours,    0,  3000000,   3000000/ethPrice, 9000000,  9000000/ethPrice,   9000000,  9000000/ethPrice));
    mileStones.push(MileStone("pre",     30 minutes, 0,  500000,    500000/ethPrice,  3000000,  3000000/ethPrice,   40000000, 40000000/ethPrice));
    mileStones.push(MileStone("public",  1 hours,    0,  ethPrice,  1,                72000000, 72000000/ethPrice,  72000000, 72000000/ethPrice));

    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = mainSaleStartTime + mileStones[mileStones.length-1].diffStartTime;

    fundsWallet = _fundsWallet;

  }

  // 设置Ehter价格，防止异常波动事件
  function setCNYPerEther(uint _price) onlyOwner public {
    require(_price != 0);
    uint oldPrice = ethPrice;
    ethPrice = _price;
    for (uint i = 0; i < mileStones.length; i++) {
      // 四舍五入，会向下取整，以太升值的话，publicICO的单笔下限会变0
      if (i != 2) {
        mileStones[i].saleMinNumEther = mileStones[i].minCNY.div(ethPrice);
      }
      mileStones[i].saleMaxNumEther = mileStones[i].maxCNY.div(ethPrice);
      mileStones[i].hardEtherCap = mileStones[i].capCNY.div(ethPrice);
    }
    ChangeEtherPrice(oldPrice, ethPrice);
  }

  // // need 4800W cpg.
  // function distributeTokens() onlyOwner public {
  //   require(!isDistributed);

  //   uint256 tokenUints = 10 ** uint256(token.decimals());
  //   require(token.balanceOf(address(this)) == 48000000*tokenUints);

  //   assert(token.transfer(privateWallet, 18000000*tokenUints));
  //   TokenDistribute(privateWallet, 18000000);
  //   assert(token.transfer(timeWallet, 19600000*tokenUints));
  //   TokenDistribute(timeWallet, 19600000);
  //   assert(token.transfer(marketWallet, 14700000*tokenUints));
  //   TokenDistribute(marketWallet, 14700000);

  //   isDistributed = true;
  // }

  /* Fallback function can be used to buy tokens */
  function () public payable {
    buyTokens(msg.sender);
  }

  /* Low level token purchase function */
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(msg.value != 0);
    require(now <= mainSaleEndTime && now >= mainSaleStartTime);
    applyCurrentState();
    uint256 etherValue = msg.value / 1 ether;
    require(etherValue >= mileStones[currentState].saleMinNumEther && etherValue <= mileStones[currentState].saleMaxNumEther);
    require(mileStones[currentState].amountEtherRaised < mileStones[currentState].hardEtherCap);

    mileStones[currentState].amountEtherRaised = mileStones[currentState].amountEtherRaised.add(etherValue);
    investedEtherAmount[msg.sender] = investedEtherAmount[msg.sender].add(etherValue);

    TokenPurchase(now, msg.sender, beneficiary, etherValue);

  }

  /* apply currentState, 0 means privateICO, 1 means preICO, 2 means publicICO */
  function applyCurrentState() internal {
    // state == 2, needless apply
    if (currentState == 2) {
      return;
    }

    uint256 diffCapEther;
    uint diffInSeconds = now - mainSaleStartTime;

    if (mileStones[currentState].amountEtherRaised <= mileStones[currentState].hardEtherCap) {
      diffCapEther = mileStones[currentState].hardEtherCap.sub(mileStones[currentState].amountEtherRaised);
    } else {
      // 0 means WeiRaised reached hardEtherCap.
      diffCapEther = 0;
    }

    if (diffInSeconds > mileStones[currentState].diffStartTime || diffCapEther < mileStones[currentState].saleMinNumEther) {
      currentState += 1;
    }
  }

  modifier afterDeadline() {
    require(now >= mainSaleEndTime);
    _;
  }

    /**
    * Withdraw the funds
    * Checks to see if time limit has been reached, sends the entire amount to the fundsWallet.
    */
  function safeWithdrawal() afterDeadline public {
      // if (!fundingGoalReached) {
      //     uint256 amount = investedEtherAmount[msg.sender];
      //     investedWeiAmount[msg.sender] = 0;
      //     if (amount > 0) {
      //         if (msg.sender.send(amount)) {
      //             FundTransfer(msg.sender, amount, false);
      //         } else {
      //             investedWeiAmount[msg.sender] = amount;
      //         }
      //     }
      // }
      require(fundsWallet == msg.sender);
      uint256 amount = this.balance;
      if (fundsWallet.send(this.balance)) {
          FundTransfer(fundsWallet, amount, false);
      }

  }

  /* Set new dates for main-sale (emergency case) */
  function setMainSaleDates(uint _mainSaleStartTime, uint _mainSaleEndTime) public onlyOwner returns (bool) {
    // require(now < _mainSaleStartTime);
    require(_mainSaleEndTime > _mainSaleStartTime);
    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = _mainSaleEndTime;
    ChangeSaleDates(mainSaleStartTime, mainSaleEndTime);
    return true;
  }

}

contract TimeVault is Ownable {
  using SafeMath for uint256;

  /** Interface flag to determine if address is for a real contract or not */
  bool public isTimeVault = true;

  /** Token we are holding */
  CPGToken public token;

  /** Address that can claim tokens */
  address public teamMultisig;
  address public adviserWallet;

  /** UNIX timestamp when tokens ICO running. */
  uint public startTime;

  uint8 public marketStep = 1;

  uint256 tokenUints;

  event Unlocked(uint256 sentEther);
  event ChangedStartTime(uint oldTime, uint newTime);


  function TimeVault(address _gameTeamMultisig, address _adviserWallet, address _token, uint _startTime) public {

    // Sanity check
    require(_gameTeamMultisig != 0x0);
    require(_adviserWallet != 0x0);
    require(_token != 0x0);
    require(now < _startTime);

    teamMultisig = _gameTeamMultisig;
    adviserWallet = _adviserWallet;  
    token = CPGToken(_token);
    startTime = _startTime;
    tokenUints = 10 ** uint256(token.decimals());

  }


// lock 494W
  function unlockAdviser() public {
    // Wait your turn!
    require(now > startTime);
    // if has no tokens, don't run.
    require(token.balanceOf(address(this)) > 0);

    // require(msg.sender == adviserWallet);
    uint difftime = now - startTime;
    
    // if (difftime > 90 days ) {
    if (difftime > 15 minutes ) {
      assert(token.transfer(adviserWallet, 4900000*tokenUints));
      Unlocked(4900000);
    }
  }

  // 653, 653, 654W
  function unlockGameTeam() public {
    // Wait your turn!
    require(now > startTime);
    // if has no tokens, don't run.
    require(token.balanceOf(address(this)) > 0);

    // require(msg.sender == teamMultisig);
    uint difftime = now - startTime;

    if (difftime > 10 minutes && marketStep == 1) {
      assert(token.transfer(teamMultisig, 6530000*tokenUints));
      marketStep += 1;
      Unlocked(6530000);
    } else if (difftime > 20 minutes && marketStep == 2) {
      assert(token.transfer(teamMultisig, 6530000*tokenUints));
      marketStep += 1;
      Unlocked(6530000);
    } else if (difftime > 30 minutes && marketStep == 3) {
      assert(token.transfer(teamMultisig, 6540000*tokenUints));
      marketStep += 1;
      Unlocked(6540000);
    }
  }

  // set new startTime.
  function setStartTime(uint newTimestamp) onlyOwner public {
    // maybe we need go ahead of time
    // require(now < newTimestamp);
    uint oldTime = startTime;
    startTime = newTimestamp;
    ChangedStartTime(oldTime, newTimestamp);
  }

  /**
   * Don't expect to just send in money and get tokens.
   */
  function() payable public {
    revert();
  }

}

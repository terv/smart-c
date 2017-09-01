pragma solidity ^0.4.13;

/**
 * @title ERC20Basic
 * @dev Интерфейс ERC179, т.е. ERC20 без механизма предоставления разрешений
 */
contract ERC20Basic {
  //Возвращает суммарное количество выпущенных монет    
  uint256 public totalSupply;
  //Возвращает количество монет принадлежащих _owner
  function balanceOf(address who) constant returns (uint256);
  //Передает _value монет на адрес _to
  function transfer(address to, uint256 value) returns (bool);
  //Событие, которое должно возникать при любом перемещении монет.
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface 
 * @dev Интерфейс ERC20
 */
contract ERC20 is ERC20Basic {
  //Разрешает пользователю _spender снимать с вашего счета (точнее со счета вызвавшего функцию пользователя) средства не более чем _value.    
  function allowance(address owner, address spender) constant returns (uint256);
  //Передает _ value монет от _from к _to
  function transferFrom(address from, address to, uint256 value) returns (bool);
  //Разрешает пользователю _spender снимать с вашего счета (точнее со счета вызвавшего функцию пользователя) средства не более чем _value.
  function approve(address spender, uint256 value) returns (bool);
  //Событие должно возникать при получении разрешения на снятие монет
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Библиотека безопасных математических операций
 */
library SafeMath {
    
  //Умножение    
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  //Деление
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  //Вычитание
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  //Сложение
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}

/**
 * @title Basic token
 * @dev Реализация ERC179
 */
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
  //Балансы всех пользователей
  mapping(address => uint256) balances;

  /**
  * @dev Передает _value монет на адрес _to
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {  
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Возвращает количество монет принадлежащих _owner
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Ownable
 * @dev Предоставляет возможность ограничивать доступ к функциям всем кроме владельца контракта
 */
contract Ownable {
    
  address public owner;

  /**
   * @dev Устанавливает владельца
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * @dev Отлуп если не владелец контракта
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Предоставляет возможность пользователю устанавливать владельца контрката, т.е. себя любимого.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

/**
 * @title Mintable token
 * @dev Предоставляет возможность выпуска новых монет, для общего понимания
 * (В нашем случает доп эмиссия не будет реализована)
 */

contract MintableToken is BasicToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
  

  /**
   * @dev Функция производства монет 
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Функция остановки производства монет 
   * Эту функцию может вызывать только владелец смарт-котракта. Она дает нам право решить когда заканчивать ICO.
   * Но ее можно выполнить и в условии, когда дойдем до суммы хардапа, либо истечет срок ICO.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}

contract SimpleTokenCoin is MintableToken {
    
    //Хранит полное название вашей монеты
    string public constant name = "Test First Coin";
    
    //Хранит короткое название вашей монеты
    string public constant symbol = "TFC";
    
    //Количество знаков после запятой
    uint32 public constant decimals = 18;
    
}


contract Crowdsale is Ownable {
    
	//Юзаем библиотеку безопасных мат операций
    using SafeMath for uint;
    
    //Отдельный адрес для эфира (В контракте ICO  обычно полученный эфир не отсылают на адрес владельца контракта, а отсылают его на отдельный адрес)
    address multisig;

    // Кол-во токенов, которое мы хотим оставить на счете смарт-контракта в конце ICO
    uint OwnerTokens;

    // Кол-во токенов, которое мы хотим получить на свой адрем в конце ICO
    uint restrictedTokens;
 
    //Адрес счета для наших токенов
    address restricted;
 
    SimpleTokenCoin public token = new SimpleTokenCoin();
 
    //Время начала ICO  — GMT в UNIX формате
    uint start;
    
    //Время проведения основного ICO в днях
    uint IcoPeriod;
	
	//Время проведения Pre-ICO в днях
    uint PreIcoPeriod;
	
	//Коэффициент бонусов Pre-ICO
	uint PreIcoKef;
		
	//Длительность первого периода бонусного ICO 
	uint IcoPeriodOne;
	//Коэффициент первого периода бонусного ICO 
	uint IcoKefOne;
	
	//Длительность второго периода бонусного ICO 
	uint IcoPeriodTwo;
	//Коэффициент второго периода бонусного ICO  
	uint IcoKefOneTwo;
 
    //Ограничение на сумму, которую нам нужно собрать
    uint hardcap;
 
    //Коэффициент пересчета эфира в наши токены
    uint rate;
 
    function Crowdsale() {
        //счет для эфира
        multisig = 0xEA15Adb66DC92a4BbCcC8Bf32fd25E2e86a2A770;
        //счет для наших собственных токенов
        restricted = 0xb3eD172CC64839FB0C0Aa06aa129f402e994e7De;
        //коэффициент пересчета в эфир
        rate = 100000000000000000000;
		
        //Начало Pre-ICO
        start = 1500379200;
		
		//Длительность основного ICO
        IcoPeriod = 30; //дней
        //Длительность Pre-ICO
        PreIcoPeriod = 14; //дней
        //Процент бонусных токенов Pre-ICO
        PreIcoKef = 50; //%
		
        //Длительность первого периода основного ICO 
        IcoPeriodOne = 2; //дней
        //Процент бонусных токенов первого периода основного ICO 
        IcoKefOne = 20; //%
		
		//Длительность второго периода основного ICO 
        IcoPeriodTwo = 5; //дней
        //Процент бонусных токенов второго периода основного ICO  
        IcoKefOneTwo = 5; //%
  
        //Ограничение выпуска в 80 млн токенов
        hardcap = 80000000;
        //На счет смарт-контракта 8 млн токенов
        OwnerTokens = 8000000;
        //На наш собственный счет 12 млн токенов
        restrictedTokens = 12000000;
    }
 
    //проверка дат ICO
    modifier saleIsOn() {
    	require(now > start && now < start + PreIcoPeriod + IcoPeriod * 1 days);
    	_;
    }
    //Проверка предела собранных средств, если дошли до границы hardcap, то запрещаем продажу токенов.	
    modifier isUnderHardCap() {
        require(multisig.balance <= hardcap);
        _;
    }
 
    function finishMinting() public onlyOwner {
        //Запрашиваем суммарное кол-во выпущенных монет
        //uint issuedTokenSupply = token.totalSupply();
        //Определяем кол-во собственных токенов
        //uint restrictedTokens = issuedTokenSupply.mul(restrictedPercent).div(100 - restrictedPercent);

        //Выпускаем монеты на наш адрес 
        token.mint(restricted, restrictedTokens);
        //Выпускаем монеты на адрес смарт-контракта 
        token.mint(owner, OwnerTokens);
    
        //Завершаем выпуск монет 
        token.finishMinting();
    }
 
    function createTokens() isUnderHardCap saleIsOn payable {
        //Пересылаем эфир на наш кошелек
        multisig.transfer(msg.value);
        //Определяем кол-во выпускаемых монет
        uint tokens = rate.mul(msg.value).div(1 ether);
        uint bonusTokens = 0;

        //Определяем кол-во бонусных монет
          
        //Pre-ICO
        if (now > start && now < start +(PreIcoPeriod * 1 days))
           {
              bonusTokens = tokens.mul(PreIcoKef / 100);
           }
		   
		//основное ICO первый период
        if (now > start +(PreIcoPeriod * 1 days) && now < start +(PreIcoPeriod + IcoPeriodOne * 1 days))
           {
              bonusTokens = tokens.mul(IcoKefOne / 100);
           }
		
		//основное ICO второй период
        if (now > start +(PreIcoPeriod + IcoPeriodOne * 1 days) && now < start +(PreIcoPeriod + IcoPeriodOne + IcoPeriodTwo * 1 days))
           {
              bonusTokens = tokens.mul(IcoKefOneTwo / 100);
           }    

        tokens += bonusTokens;
        token.mint(msg.sender, tokens);
    }
 
    function() external payable {
        createTokens();
    }
    
}

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
    
    //!!!Добавить проверить на переполнение sub и add
      
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
 * @title Standard ERC20 token
 *
 * @dev Реализация ERC20
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Передает _value монет от _from к _to
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Разрешает пользователю _spender снимать с вашего счета (точнее со счета вызвавшего функцию пользователя) средства не более чем _value
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Разрешает пользователю _spender снимать с вашего счета (точнее со счета вызвавшего функцию пользователя) средства не более чем _value
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
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

contract MintableToken is StandardToken, Ownable {
    
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

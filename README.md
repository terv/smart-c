# smart-c

Смарт-контракты ethereum

"ERC20" - стандарт

Методы:
function totalSupply() constant returns (uint256 totalSupply)
function balanceOf(address _owner) constant returns (uint256 balance)
function transfer(address _to, uint256 _value) returns (bool success)
function transferFrom(address _from, address _to, uint256 _value) returns (bool success)
function approve(address _spender, uint256 _value) returns (bool success)
function allowance(address _owner, address _spender) constant returns (uint256 remaining)

События:
event Transfer(address indexed _from, address indexed _to, uint256 _value)
event Approval(address indexed _owner, address indexed _spender, uint256 _value)

*********************************************************************************************

"ERC179"  - стандарт

Методы:
uint public totalSupply;
function balanceOf(address who) constant returns (uint);
function transfer(address to, uint value);

События:
event Transfer(address indexed from, address indexed to, uint value);

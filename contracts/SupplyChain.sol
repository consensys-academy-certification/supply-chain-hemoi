// Implement the smart contract SupplyChain following the provided instructions.
// Look at the tests in SupplyChain.test.js and run 'truffle test' to be sure that your contract is working properly.
// Only this file (SupplyChain.sol) should be modified, otherwise your assignment submission may be disqualified.

pragma solidity ^0.5.0;

contract SupplyChain {

  address payable owner;
  constructor() public {
    owner = msg.sender;
  }
  uint itemIdCount = 0;
  // Create a variable named 'itemIdCount' to store the number of items and also be used as reference for the next itemId.
  enum State {
    ForSale, 
    Sold, 
    Shipped, 
    Received
  }
  // Create an enumerated type variable named 'State' to list the possible states of an item (in this order): 'ForSale', 'Sold', 'Shipped' and 'Received'.
  struct Item {
    string name;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }
  // Create a struct named 'Item' containing the following members (in this order): 'name', 'price', 'state', 'seller' and 'buyer'. 
  mapping (uint => Item) items;
  // Create a variable named 'items' to map itemIds to Items.
  event StateChanges(uint _id, State);
  // Create an event to log all state changes for each item.


  modifier onlyOwner() {
    require (msg.sender==owner);
    _;
  }
  // Create a modifier named 'onlyOwner' where only the contract owner can proceed with the execution.
  modifier checkState(uint _id, State _state) {
    require(items[_id].state == _state);
    _;
  }
  // Create a modifier named 'checkState' where the execution can only proceed if the respective Item of a given itemId is in a specific state.
  modifier checkCaller (uint _id, bool isSeller){
    if (isSeller == true){
      require (items[_id].seller == msg.sender);
      _;
    } else {
      require (items[_id].buyer == msg.sender);
      _;
    }
  }
  // Create a modifier named 'checkCaller' where only the buyer or the seller (depends on the function) of an Item can proceed with the execution.
  modifier checkValue (uint value){
    require(msg.value >=value);
    _;
  }
  // Create a modifier named 'checkValue' where the execution can only proceed if the caller sent enough Ether to pay for a specific Item or fee.


  function addItem (string memory _name, uint _price) checkValue(1 finney) public payable{
    items[itemIdCount++] = Item(_name, _price, State.ForSale, msg.sender, address(0));
    if(msg.value > 1 finney) {
      msg.sender.transfer(msg.value - 1 finney);
    }

    emit StateChanges(itemIdCount-1, State.ForSale);
  }
  // Create a function named 'addItem' that allows anyone to add a new Item by paying a fee of 1 finney. Any overpayment amount should be returned to the caller. All struct members should be mandatory except the buyer.
  function buyItem (uint _id) checkState(_id, State.ForSale) external payable {
    Item storage targetItem = items[_id];
    targetItem.state = State.Sold;
    targetItem.buyer = msg.sender;

    if(msg.value > targetItem.price){
      msg.sender.transfer(msg.value-targetItem.price);
      targetItem.seller.transfer(targetItem.price);
    }

    emit StateChanges(_id, State.Sold);
  }
  // Create a function named 'buyItem' that allows anyone to buy a specific Item by paying its price. The price amount should be transferred to the seller and any overpayment amount should be returned to the buyer.
  function shipItem (uint _id) checkCaller(_id, true) checkState(_id, State.Sold) external{
    Item storage targetItem = items[_id];
    targetItem.state = State.Shipped;

    emit StateChanges(_id, State.Shipped);
  }
  // Create a function named 'shipItem' that allows the seller of a specific Item to record that it has been shipped.
  function receiveItem (uint _id) checkCaller(_id, false) checkState(_id, State.Shipped)  external{
    Item storage rItem = items[_id];
    rItem.state = State.Received;

    emit StateChanges(_id, State.Received);
  }
  // Create a function named 'receiveItem' that allows the buyer of a specific Item to record that it has been received.
  function getItem (uint _id) external view returns(string memory, uint, State, address, address){
    Item storage gItem = items[_id];
    return (gItem.name, gItem.price, gItem.state, gItem.seller, gItem.buyer);
  }
  // Create a function named 'getItem' that allows anyone to get all the information of a specific Item in the same order of the struct Item. 
  function withdrawFunds () external onlyOwner {
    owner.transfer(address(this).balance);
  }
  // Create a function named 'withdrawFunds' that allows the contract owner to withdraw all the available funds.

}

pragma solidity >= 0.4.15;

contract Market {

  event OfferAdded(uint indexed id, string product, uint price);
  event OfferTaken(uint indexed id);
  event OfferConfirmed(uint indexed id);
  event Whitelisted(address indexed addr, bool value);

  enum Status {
    OFFERED,
    TAKEN,
    CONFIRMED,
    ABORTED
  }

  struct Offer {
    string product;
    uint price;
    address arbiter;
    address creator;
    address taker;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
  }

  modifier restricted {
    require(whitelisted(msg.sender == owner));
  }

  Offer[] public offers;
  mapping (address => bool) public whitelisted;
  address owner;

  function Market() {
    owner = msg.sender;
  }

  function setWhitelisted(address addr, bool value)
  onlyOwner {
    whitelisted[addr] = value;
    Whitelisted(addr, value);
  }

  function addOffer(string product, uint price, address arbiter)
  restricted returns (uint) {
    offers.push(Offer({
      product: product,
      price: price,
      arbiter: arbiter,
      taker: 0,
      creator: msg.sender
    }));
    uint id = offers.length - 1;
    OfferAdded(id, product, price);
    return id;
  }

  function setArbiter(uint id, address arbiter) {

  }

  function takeOffer(uint id, address arbiter) {

  }

  function confirmOffer(uint id) {

  }

  function resolve(uint id, bool delivered, bool burn) {

  }

}

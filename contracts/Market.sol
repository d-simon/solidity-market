pragma solidity >= 0.4.15;

contract Market {

  event OfferAdded(uint indexed id, string product, uint price);
  event OfferTaken(uint indexed id);
  event OfferConfirmed(uint indexed id);
  event OfferAborted(uint indexed id);
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
    Status status;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier restricted {
    require(whitelisted[msg.sender] == true);
    _;
  }

  modifier inState(uint id, Status s) {
    require(offers[id].status == s);
    _;
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
    offers.push(
      Offer({
        product: product,
        price: price,
        arbiter: arbiter,
        taker: 0,
        creator: msg.sender,
        status: Status.OFFERED
      })
    );
    uint id = offers.length - 1;
    OfferAdded(id, product, price);
    return id;
  }

  function setArbiter(uint id, address arbiter)
  inState(id, Status.OFFERED) {
    Offer storage offer = offers[id]; // we're creating it in the storage, because it will otherwise copy it from storage to memory, this way we keep a refere
    require(offer.creator == msg.sender);
    offer.arbiter = arbiter;
  }

  function takeOffer(uint id, address arbiter)
  inState(id, Status.OFFERED) payable restricted { // theoreticaly a malicious owner could cause harm here (restricted)
    Offer storage offer = offers[id];
    require(offer.creator != msg.sender); // can't take your own offer :-)
    require(offer.price == msg.value);
    require(offer.arbiter == arbiter);
    offer.taker = msg.sender;
    offer.status = Status.TAKEN;
    OfferTaken(id);
  }

  function confirmOffer(uint id)
  inState(id, Status.TAKEN){
    Offer storage offer = offers [id];
    require(offer.taker == msg.sender);
    finalize(id);
  }

  function finalize(uint id)
  internal {
    Offer storage offer = offers [id];
    offer.creator.transfer(offer.price);
    offer.status = Status.CONFIRMED;
    OfferConfirmed(id);
  }

  function resolve(uint id, bool delivered) //, bool burn)
  inState(id, Status.TAKEN) {
    Offer storage offer = offers [id];
    require(offer.arbiter == msg.sender);
    if (delivered) {
      finalize(id);
    } else {
      offer.taker.transfer(offer.price);
      offer.status = Status.ABORTED;
      OfferAborted(id);
    }
  }

}

market = Market.at(Market.address);
var [owner, creator, taker, arbiter] = web3.eth.accounts;
market.setWhitelisted(creator, true, { from: owner })
market.setWhitelisted(taker, true, { from: owner })
market.addOffer('TestProduct', 500, arbiter, { from: creator })
market.takeOffer(0, arbiter, { from: taker, value: 500 })

market.resolve(0, true, false, { from: arbiter })

market.confirmOffer(0, { from : taker })

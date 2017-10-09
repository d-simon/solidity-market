require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(web3.BigNumber))
    .should();

var Market = artifacts.require("./Market.sol");
var ReputationToken = artifacts.require("./ReputationToken");

const promisify = (inner) => new Promise((resolve, reject) => inner((err, res) => err ? reject(err) : resolve(res)));
const getBalance = (addr) => promisify((cb) => web3.eth.getBalance(addr, cb))
const getTransaction = (txHash) => promisify((cb) => web3.eth.getTransaction(txHash, cb))

const computeCost = async (receipt) => {
  let { gasPrice } = await getTransaction(receipt.transactionHash);
  return gasPrice.times(receipt.gasUsed);
}

contract('Market test', function(accounts) {

  const [ owner, creator, taker, arbiter, notlisted ] = accounts

  const price = web3.toBigNumber(100);
  const product = 'Product';
  const zero = "0x0000000000000000000000000000000000000000";

  const OFFERED = web3.toBigNumber(0);
  const TAKEN = web3.toBigNumber(1);
  const CONFIRMED = web3.toBigNumber(2);
  const ABORTED = web3.toBigNumber(3);

  it('should whitelist accounts', async function() {
    let market = await Market.deployed();

    let { logs } = await market.setWhitelisted(creator, true, { from: owner });

    let { event, args } = logs[0];

    event.should.equal('Whitelisted')
    args.should.deep.equal({
      addr: creator,
      value: true
    })

    ;(await market.whitelisted(creator)).should.equal(true)

    await market.setWhitelisted(arbiter, true, { from: owner })
    await market.setWhitelisted(taker, true, { from: owner })
  })

  it('should not whitelist accounts', async function() {
    let market = await Market.deployed();

    await market.setWhitelisted(notlisted, true, {
      from: creator
    }).should.be.rejectedWith('invalid opcode')
  })

  it('should addOffer', async function() {
    let market = await Market.deployed();

    let { logs } = await market.addOffer(product, price, arbiter, { from: creator });
    let { event, args } = logs[0];

    event.should.equal('OfferAdded')
    args.should.deep.equal({
      product,
      price,
      id: web3.toBigNumber(0)
    })

    ;(await market.offers(0)).should.deep.equal([
      product,
      price,
      arbiter,
      creator,
      zero,
      OFFERED
    ])
  })

  it('should takeOffer', async function() {
    let market = await Market.deployed();

    let expectedBalanceTaker = (await getBalance(taker)).minus(price)

    let { logs, receipt } = await market.takeOffer(0, arbiter, {
      from: taker,
      value: price
    });

    expectedBalanceTaker = expectedBalanceTaker.minus(await computeCost(receipt))

    let { event, args } = logs[0];

    event.should.equal('OfferTaken');
    args.should.deep.equal({
      id: web3.toBigNumber(0)
    })

    ;(await market.offers(0)).should.deep.equal([
      product,
      price,
      arbiter,
      creator,
      taker,
      TAKEN
    ])

    ;(await getBalance(taker)).should.deep.equal(expectedBalanceTaker);
    ;(await getBalance(market.address)).should.deep.equal(price);
  })

  it('should confirmOffer', async function() {
    let market = await Market.deployed();
    let expected = (await getBalance(creator)).plus(price);
    let id = web3.toBigNumber(0);
    let { logs } = await market.confirmOffer(id, {
      from: taker
    });
    let { event, args } = logs[0]
    event.should.equal('OfferConfirmed')
    args.should.deep.equal(args, { id })
    ;(await getBalance(market.address)).should.bignumber.equal(0)
    ;(await getBalance(creator)).should.deep.equal(expected)
  })
})

# Update to Tiered Presale

## Summary

Users will be able to come to the platform, and decide which type of users they want to be:

1. Participants in presales
2. Presales creators

When they create a presale, this will be a grid presale. At the moment of presale creation they will be able to decide the following:

1. Tokens amount to sell
2. Tokens that will be used to pair liquidity when finalizing the presale
3. Number of grids per layer (up to 10x10)
4. How long the presale will last, with starting time and ending time

Assuming a presale has started, once it sells out all grids, it will move to the next layer. And the next layer each time it sells out the grid.

Portion of funds raised in level 2 will be distribtued back to L1, portion from l3 to l2, and so on.
IF a layer doesn't sell out and presale stops
(e.g a 3x3 layer, sells out 8/9 in layer 2), only people from layer 1 will receive their tokens. The other 8/9 should have bought earlier.

needs to modify the logic for deposit and withdraw to take care of the layers we're in and the business logic for refunds to previous layers.

The smart contract already has logic to find what layer we're in and RAISE the tier by the amount the user wants (e.g each layer is 2x, or each layer is 50% higher, etc.). These functions are called "shouldIncreaseLayer()", "shouldIncreaseLayerCalculator()"

---

1. MUST IMPLEMENT FACTORY. Make it so the factory stores an array of all smart contracts addresses deployed.

2. Don't make it as a proxy. Indeed not worth it.

3. a,b,c,d => team can answer.

Regarding 3 c, IF each layer is a contract, this may create a problem because say we deploy on ethereum or arbitrum, SPACE COSTS MONEY. When a layer ends, the user will deploy the smart contract which will cost too much with the risk of having a layer that may not end. IMO would explore building it using an ID and match whatever is raised to that ID.

E.g round 1 is 0
Round 2 is 1
Etc.
Then have a mapping for

mapping(uint256 => uint256) public fundRaised;

And store the amounts raised by ID

For users to keep track of, perhaps
mapping(address => mapping(uint256 => uint256)) public userContributionByLayer 3.

- a. Deposits should not be refundable 10 min before layer ends or some fixed time like that (even kickstarter does this) - SURE THIS IS FINE IF IN WITHIN THE QUOTE
- b. The rewards that are passed to previous layers. are those in the raised amount or in tokens? IN RAISED AMOUNT
- c. Is each layer it's own contract? DOESN'T MATTER
- d. Each Grid amount, is it 1 user per Grid amount or can multiple users go into a single Grid item. 1 USER PER GRID

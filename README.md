# Update to Tiered Presale

## Summary

---

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

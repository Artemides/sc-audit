# TSWAP Contract Review

# [H-1] Unused `@param: deadline` at `Tswap:deposit` function, makes deposit transaction still runnable once deadline passed.

**Description:** `@param:deadline` indicates user that deposits will occur only within a deadline, ever since no deadline checks are used `deposit` will execute.

```javascript
  function deposit(
        uint256 wethToDeposit,
        uint256 minimumLiquidityTokensToMint,
        uint256 maximumPoolTokensToDeposit,
     @> uint64 deadline
    )
```

**Impact:** Succesful deposits after deadlines, it executes lapsed transaction damagin Protocol.

**Proof of Concept:**

**Recommended mitigation**

- Apply `Modifier::revertIfDeadlinePassed` to `Tswap::deposit` function.

```diff
function deposit(
        uint256 wethToDeposit,
        uint256 minimumLiquidityTokensToMint,
        uint256 maximumPoolTokensToDeposit,
        uint64 deadline
    )
        external
+       revertIfDeadlinePassed(deadline)
        revertIfZero(wethToDeposit)
        returns (uint256 liquidityTokensToMint)
    {
        //impl..
    }
```

# [H-2] Wrong Swap fee settled for `Tswap::getInputAmountBasedOnOutput` as `1_0000`.

**Description:** Tswap Protocol settles `0.03%` fee on swap. However, `getInputAmountBasedOnOutput` function uses `1_0000` factr in the numerator.

**Impact:** Makes the protocol charges higher fees on swaps `0.3%`.

**Proof of concept:**

The usae of a Factor with `10_000` causes a `0.3%` Fee, which is `10x` times specified Fee on swaps in Protocol.

**Recommended Mitigation:**

Use correct factor for numerator in the Formula:

```diff
  function getInputAmountBasedOnOutput(
        uint256 outputAmount,
        uint256 inputReserves,
        uint256 outputReserves
    )
        public
        pure
        revertIfZero(outputAmount)
        revertIfZero(outputReserves)
        returns (uint256 inputAmount)
    {
        // @audit wrong fee settled 10_000
        return
-           ((inputReserves * outputAmount) * 10000) /
+           ((inputReserves * outputAmount) * 10000) /
            ((outputReserves - outputAmount) * 997);
    }
```

# [H-3] No Slippage protection on `Tswap::swapExactOutput` makes users possible undesired `poolToken` amounts.

**Description:** `Tswap::swapExactOutput` does not contain a protection in cases where `PoolToken` input amount on swap are huge due to pool demand and price spot movement, in case of large spot price movement, PoolTokens might be expensiver than usual requiring much more input tokens in order to execute a swap.

**Impact:** Damages user tokens positions, possible swapping undesired amounts.

**Proof of concept:**

**Recommend mitigation:**

1. include `maxInputAmount` param at `Tswap::swapExactOutput`.
2. require `inputAmount` to be less or equal than `maxInputAmount`.

```diff
  function swapExactOutput(
        IERC20 inputToken,
+        uint256 maxInputAmount,
        IERC20 outputToken,
        uint256 outputAmount,
        uint64 deadline
    )
        public
        revertIfZero(outputAmount)
        revertIfDeadlinePassed(deadline)
        returns (uint256 inputAmount)
    {
        uint256 inputReserves = inputToken.balanceOf(address(this));
        uint256 outputReserves = outputToken.balanceOf(address(this));

        inputAmount = getInputAmountBasedOnOutput(
            outputAmount,
            inputReserves,
            outputReserves
        );
+        require(inputAmount<= maxInputAmount);
        _swap(inputToken, inputAmount, outputToken, outputAmount);
    }


```

# [H-4] Incentives on every 10 swaps breaks `Protocol Invariant`

**Description:** Protocol's core invariants says: _Our system works because the ratio of Token A & WETH will always stay the same. Well, for the most part. Since we add fees, our invariant technially increases._, which get's broken by `Transfering Incentives` each 10th swap.

**Impact:** Damages severly the protocol, manipulating `Tswap::PriceSpot`, allowing exploits to manipulate exactly at `10th` swap in their favor.

**Proof of concept:**

**Recommended Mitigation:**

- Use alternative swapping models

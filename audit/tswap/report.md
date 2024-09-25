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

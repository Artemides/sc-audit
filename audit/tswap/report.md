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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "./../../../src/tswap/PoolFactory.sol";
import "./../mocks/MockERC20.sol";
contract PoolHandler is Test {
    PoolFactory factory;
    TSwapPool pool;
    MockERC20 weth;
    MockERC20 token;

    address user = makeAddr("user");
    address lp = makeAddr("lp");

    // Ghost States
    uint256 expectedDx;
    uint256 expectedDy;

    uint256 Dx;
    uint256 Dy;

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = MockERC20(pool.getWeth());
        token = MockERC20(pool.getPoolToken());
    }

    // function setUp() public {
    //     weth = new MockERC20();
    //     token = new MockERC20();
    //     factory = new PoolFactory(address(weth));
    //     pool = TSwapPool(factory.createPool(address(token)));
    // }

    function addLiquidity(uint256 _amountY) public {
        uint256 amountY = bound(
            _amountY,
            pool.getMinimumWethDepositAmount(),
            weth.balanceOf(address(pool))
        );

        expectedDy = amountY;
        expectedDx = pool.getPoolTokensToDepositBasedOnWeth(amountY);

        uint256 initialWethReserves = weth.balanceOf(address(pool));
        uint256 initialTokenReserves = token.balanceOf(address(pool));

        vm.startPrank(lp);

        weth.mint(lp, Dy);
        token.mint(lp, expectedDx);
        weth.approve(address(this), Dy);
        token.approve(address(pool), expectedDx);

        pool.deposit(amountY, 0, expectedDx, uint64(block.timestamp));
        vm.stopPrank();
        uint256 wethReserves = weth.balanceOf(address(pool));
        uint256 tokenReserves = token.balanceOf(address(pool));

        Dx = tokenReserves - initialTokenReserves;
        Dy = wethReserves - initialWethReserves;
    }

    function swapExactAmountY(uint256 _amountY) public {
        if (
            weth.balanceOf(address(pool)) <= pool.getMinimumWethDepositAmount()
        ) {
            return;
        }

        uint256 amountY = bound(
            _amountY,
            pool.getMinimumWethDepositAmount(),
            weth.balanceOf(address(pool))
        );
        if (amountY == weth.balanceOf(address(pool))) {
            return;
        }

        uint256 initialWethReserves = weth.balanceOf(address(pool));

        expectedDy = amountY;
        expectedDx = pool.getInputAmountBasedOnOutput(
            amountY,
            token.balanceOf(address(pool)),
            initialWethReserves
        );
        if (expectedDx > type(uint64).max) {
            return;
        }

        if (token.balanceOf(user) < expectedDx) {
            token.mint(user, expectedDx - token.balanceOf(user) + 1);
        }

        vm.startPrank(user);
        token.approve(address(pool), expectedDx);

        Dx = pool.swapExactOutput(
            token,
            weth,
            expectedDy,
            uint64(block.timestamp)
        );
        Dy = initialWethReserves - weth.balanceOf(address(pool));

        vm.stopPrank();
    }
}

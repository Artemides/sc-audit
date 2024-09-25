// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;
import "forge-std/StdInvariant.sol";
import "forge-std/Test.sol";

import "./../mocks/MockERC20.sol";
import "./../../../src/tswap/PoolFactory.sol";
import "./Handler.sol";

contract FuzzInvariantTswap is StdInvariant, Test {
    PoolFactory factory;
    TSwapPool pool;
    MockERC20 weth;
    MockERC20 token;

    PoolHandler handler;

    int256 constant STARTING_X = 100e18; // starting ERC20
    int256 constant STARTING_Y = 50e18; // starting WETH

    function setUp() public {
        weth = new MockERC20();
        token = new MockERC20();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(token)));

        token.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));
        token.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        pool.deposit(
            uint256(STARTING_Y),
            uint256(STARTING_Y),
            uint256(STARTING_X),
            uint64(block.timestamp)
        );
        handler = new PoolHandler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = PoolHandler.addLiquidity.selector;
        selectors[1] = PoolHandler.swapExactAmountY.selector;

        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );
        targetContract(address(handler));
    }

    function invariant_deltaXFollowsMath() public {
        assertEq(handler.Dx(), handler.expectedDx());
    }

    function invariant_deltaYFollowsMath() public {
        assertEq(handler.Dy(), handler.expectedDy());
    }
}

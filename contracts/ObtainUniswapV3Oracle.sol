// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";
import "./TickMath.sol";

interface IUniswapV3Factory {
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

interface IUniswapV3Pool {
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        );

    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );

    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function liquidity() external view returns (uint128);
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

contract ObtainUniswapV3Oracle {
    //v3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984
    //uint16 public cardinalitys;
    function getSqrtTWAP(uint32 twapInterval,address token0,address token1,address v3Factory)
        external
        view
        returns (uint160 sqrtPriceX96,uint16 cardinalitys)
    {
        IUniswapV3Pool pool = IUniswapV3Pool(getTargetPool(token0,token1,v3Factory));
        // pool.increaseObservationCardinalityNext(10);
        (, , uint16 index,uint16 cardinality, , , ) = pool.slot0();
        cardinalitys = cardinality;
        (uint32 targetElementTime, , , bool initialized) = pool.observations(
            (index + 1) % cardinality
        );
        if (!initialized) {
            (targetElementTime, , , ) = pool.observations(0);
        }
        uint32 delta = uint32(block.timestamp) - targetElementTime;
        if (delta == 0) {
            (sqrtPriceX96, , , , , , ) = pool.slot0();
        } else {
            if (delta < twapInterval) twapInterval = delta;
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)
            (int56[] memory tickCumulatives, ) = pool.observe(secondsAgos);
            // tick(imprecise as it's an integer) to price
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24(
                    (tickCumulatives[1] - tickCumulatives[0]) /
                        int56(uint56(twapInterval))
                )
            );
        }
    }

    function getTargetPool(
        address token0,
        address token1,
        address v3Factory
    ) public view returns (address) {
        uint24[3] memory v3Fees;
        v3Fees[0] = 500;
        v3Fees[1] = 3000;
        v3Fees[2] = 10000;
        // find out the pool with best liquidity as target pool
        address pool;
        address tempPool;
        uint256 poolLiquidity;
        uint256 tempLiquidity;
        for (uint256 i = 0; i < v3Fees.length; i++) {
            tempPool = IUniswapV3Factory(v3Factory).getPool(
                token0,
                token1,
                v3Fees[i]
            );
            if (tempPool == address(0)) continue;
            tempLiquidity = uint256(IUniswapV3Pool(tempPool).liquidity());
            // use the max liquidity pool as index price source
            if (tempLiquidity > poolLiquidity) {
                poolLiquidity = tempLiquidity;
                pool = tempPool;
            }
        }
        return pool;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "hardhat/console.sol";
// ----------------------INTERFACE------------------------------

// Aave
// https://docs.aave.com/developers/the-core-protocol/lendingpool/ilendingpool

interface ILendingPool {
    /**
     * Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of theliquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

// UniswapV2

// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IERC20.sol
// https://docs.uniswap.org/protocol/V2/reference/smart-contracts/Pair-ERC-20
interface IERC20 {
    // Returns the account balance of another account with address _owner.
    function balanceOf(address owner) external view returns (uint256);

    /**
     * Allows _spender to withdraw from your account multiple times, up to the _value amount.
     * If this function is called again it overwrites the current allowance with _value.
     * Lets msg.sender set their allowance for a spender.
     **/
    function approve(address spender, uint256 value) external; // return type is deleted to be compatible with USDT

    /**
     * Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
     * The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
     * Lets msg.sender send pool tokens to an address.
     **/
    function transfer(address to, uint256 value) external returns (bool);
}


interface DERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 value) external; // return type is deleted to be compatible with USDT
    function transfer(address to, uint256 value) external;
}

// https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IWETH.sol
interface IWETH is IERC20 {
    // Convert the wrapped token back to Ether.
    function withdraw(uint256) external;
}



// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Callee.sol
// The flash loan liquidator we plan to implement this time should be a UniswapV2 Callee
interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
// https://docs.uniswap.org/protocol/V2/reference/smart-contracts/factory
interface IUniswapV2Factory {
    // Returns the address of the pair for tokenA and tokenB, if it has been created, else address(0).
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
// https://docs.uniswap.org/protocol/V2/reference/smart-contracts/pair
interface IUniswapV2Pair {
    /**
     * Swaps tokens. For regular swaps, data.length must be 0.
     * Also see [Flash Swaps](https://docs.uniswap.org/protocol/V2/concepts/core-concepts/flash-swaps).
     **/
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    /**
     * Returns the reserves of token0 and token1 used to price trades and distribute liquidity.
     * See Pricing[https://docs.uniswap.org/protocol/V2/concepts/advanced-topics/pricing].
     * Also returns the block.timestamp (mod 2**32) of the last block during which an interaction occured for the pair.
     **/
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// ----------------------IMPLEMENTATION------------------------------

contract LiquidationOperator is IUniswapV2Callee {
    uint8 public constant health_factor_decimals = 18;

    // TODO: define constants used in the contract including ERC-20 tokens, Uniswap Pairs, Aave lending pools, etc. */
    //    *** Your code here ***
    ILendingPool aav2LendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IUniswapV2Factory uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address targetUser = 0x59CE4a2AC5bC3f5F225439B2993b86B42f6d3e9F;
    address WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDTAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address WBTCAddress = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    IWETH WETHToken;
    DERC20 USDTToken;
    IERC20 WBTCToken;



    IUniswapV2Pair wethUSDTPair;
    IUniswapV2Pair wethWBTCPair;
    IUniswapV2Pair usdtWBTCPair;

    IUniswapV2Pair ethUSDTPair;
    IUniswapV2Pair ethWBTCPair;

    uint256 wethUSDTPair_weth_reserve;
    uint256 wethUSDTPair_usdt_reserve;
    uint256 wethWBTCPair_weth_reserve;
    uint256 wethWBTCPair_wbtc_reserve;
    uint256 usdtWBTCPair_usdt_reserve;
    uint256 usdtWBTCPair_wbtc_reserve;

    uint256 usdt_outstanding;



    // END TODO

    // some helper function, it is totally fine if you can finish the lab without using these function
    // https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    // safe mul is not necessary since https://docs.soliditylang.org/en/v0.8.9/080-breaking-changes.html
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // some helper function, it is totally fine if you can finish the lab without using these function
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    // safe mul is not necessary since https://docs.soliditylang.org/en/v0.8.9/080-breaking-changes.html
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    constructor() {
        // TODO: (optional) initialize your contract
        //   *** Your code here ***
        // END TODO

        wethUSDTPair = IUniswapV2Pair(uniswapFactory.getPair(WETHAddress, USDTAddress));
        wethWBTCPair = IUniswapV2Pair(uniswapFactory.getPair(WETHAddress, WBTCAddress));
        usdtWBTCPair = IUniswapV2Pair(uniswapFactory.getPair(USDTAddress, WBTCAddress));

        WETHToken = IWETH(WETHAddress);
        USDTToken = DERC20(USDTAddress);
        WBTCToken = IERC20(WBTCAddress);
        
        uint32 t1;
        uint32 t2;
        uint32 t3;
        (wethUSDTPair_weth_reserve, wethUSDTPair_usdt_reserve, t1) = wethUSDTPair.getReserves();
        (wethWBTCPair_wbtc_reserve, wethWBTCPair_weth_reserve, t2) = wethWBTCPair.getReserves();
        (usdtWBTCPair_wbtc_reserve, usdtWBTCPair_usdt_reserve, t3) = usdtWBTCPair.getReserves();
        console.log("IN the USDT-WBTC pool, the number of WBTC is %s : ths number fo USDT is %s.", usdtWBTCPair_wbtc_reserve, usdtWBTCPair_usdt_reserve);
        console.log("In the USDT-WETH pool, the number of USDT is %s : the number of WETH is %s.", wethUSDTPair_usdt_reserve, wethUSDTPair_weth_reserve);
    }



    // TODO: add a `receive` function so that you can withdraw your WETH
    //   *** Your code here ***
    receive() external payable {}
    // END TODO

    // required by the testing script, entry for your liquidation call
    function operate() external {

        address invoker = msg.sender;
    
        (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 lTV,
            uint256 healthFactor
    
        ) = aav2LendingPool.getUserAccountData(targetUser);
        require(healthFactor < 10 ** health_factor_decimals, "The target user does not need to be liquidated");
        uint256 eth_outstanding = totalDebtETH - totalCollateralETH * 2 / 3;
        usdt_outstanding = getAmountOut(eth_outstanding, wethUSDTPair_weth_reserve, wethUSDTPair_usdt_reserve) / 500;
        
        console.log("The USDT outstanding is %s", usdt_outstanding);
        if (usdt_outstanding > wethUSDTPair_usdt_reserve) usdt_outstanding = wethUSDTPair_usdt_reserve;
        wethUSDTPair.swap(0, usdt_outstanding, address(this), abi.encode("data"));

        console.log("Going back to the caller function.");
        uint256 wethAmount = getAmountOut(USDTToken.balanceOf(address(this)), wethUSDTPair_usdt_reserve, wethUSDTPair_weth_reserve);
        console.log("Before the WETH - USDT exchange, I have %s WETH and I have %s USDT | The amount WETH I want is %s", WETHToken.balanceOf(address(this)), USDTToken.balanceOf(address(this)), wethAmount);
        wethAmount = wethAmount * 997 / 1000 - 1;
        USDTToken.transfer(address(wethUSDTPair), USDTToken.balanceOf(address(this)));
        wethUSDTPair.swap(wethAmount, 0, address(this), new bytes(0));
        console.log("After the WETH - USDT exchange, I have %s WETH", WETHToken.balanceOf(address(this)));
        WETHToken.withdraw(WETHToken.balanceOf(address(this)));
        console.log("After the WETH withdraw, I have %s WETH", WETHToken.balanceOf(address(this)));
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        console.log("Callback function is triggered");
    

        console.log("Before the liquidation, in the current account: the amount of USDT is %s | the amount of WBTC is %s", USDTToken.balanceOf(address(this)), WBTCToken.balanceOf(address(this)));
        USDTToken.approve(address(aav2LendingPool), USDTToken.balanceOf(address(this)));
        aav2LendingPool.liquidationCall(WBTCAddress, USDTAddress, targetUser, USDTToken.balanceOf(address(this)), false);
        console.log("After the liquidation, in the current account: the amount of USDT is %s | the amount of WBTC is %s", USDTToken.balanceOf(address(this)), WBTCToken.balanceOf(address(this)));

        uint256 amountUSDT = getAmountOut(WBTCToken.balanceOf(address(this)), usdtWBTCPair_wbtc_reserve, usdtWBTCPair_usdt_reserve);
        WBTCToken.transfer(address(usdtWBTCPair), WBTCToken.balanceOf(address(this)));
        console.log("Amount USDT variable is %s --- USDT-WBTC Pool WBTC Reserve %s: USDT Reserve %s.", amountUSDT, usdtWBTCPair_wbtc_reserve, usdtWBTCPair_usdt_reserve);
        console.log("USDT <-> WBTC swap: Before the swap %s USDT", USDTToken.balanceOf(address(this)));
        usdtWBTCPair.swap(0, amountUSDT, address(this), new bytes(0));
        console.log("USDT <-> WBTC swap: After the swap %s USDT", USDTToken.balanceOf(address(this)));


        console.log("The usdt I owe is %s | I own is %s", amount1, USDTToken.balanceOf(address(this)));
        require(amount1 <= USDTToken.balanceOf(address(this)), "It is a lossing money trade");
        uint fee = (amount1 * 3) / 1000 + 1;
        uint amountToRepay = amount1 + fee;
        console.log("Before repaying, I have %s USDT.", USDTToken.balanceOf(address(this)));
        console.log("Amount to repay: %s", amountToRepay);
        amountToRepay = amountToRepay * 1003 / 1000 + 1;
        USDTToken.transfer(msg.sender, amountToRepay);
        console.log("After repaying, I have %s USDT", USDTToken.balanceOf(address(this)));
    }
}

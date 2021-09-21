# WBTC Bancor Yield Farming Strategy

<img src="https://user-images.githubusercontent.com/47485188/134218268-9c6e493a-5e72-4c7d-a3f9-2e4054be0e93.png">

## Deposit
The strategy takes WBTC as deposit and deposits them to Bancor's WBTC/BNT Liquidity pool. 

## Harvest
Including the fees, we get BNT rewards, which are converted into WBTC and then deposited back into the strategy.
## Pros 
1. First one ofcourse, single-sided liquidity. Unlike Uniswap's Liquidity Pools where we have to add equal amounts of both tokens, in Bancor we can provide single-sided liquidity. So instead of adding 50%-WBTC 50%-BNT, the strategy adds 100% WBTC to the pool. 
2. Protection from <strong>Impermanent Loss</strong>.
3. High Rewards.

## Cons
 1. Everytime a deposit is made, a new deposit id is added, so this results in high gas costs while calculating total balance of Pool,
because we have to query each id individually to get the wbtc balance in each deposit. Similarly, while withdrawing we have
to query each id until the required amount is withdrawn. In short, <strong>High Gas Costs</strong>.
2. Due to Bancor's promise of protection from impermanent loss, sometimes while withdrawing WBTC from the pool, if sufficient WBTC liquidity is not available then Bancor Protocol will makeup with BNT tokens instead.

## Expected Yield
As of Sept 21, 2021

Fees APR => <strong>1.26%</strong><br>
BNT Rewards APR => <strong>53.08%</strong><br>
WBTC Rewards APR => <strong>6.42%</strong>
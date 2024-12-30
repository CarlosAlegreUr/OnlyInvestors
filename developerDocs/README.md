
## Investing 📈

1. Call `IncomeValt::invest()`
2. After `s_investmentStartDelay` has passed (min 1 day) -> `IncomeVault::finalizeInvestment()`
3. Next time a dividend is payed you will get your part.

## Distribution 💸

1. Every `X` time, an approved income source can call: `IncomeSourceSender::distributeIncome()`
2. Which will update the dividends accrued per share on `IncomeVault`.

## Claiming 💰

1. In between dividends distribution rounds you must call `IncomeVault::collectDividend()`.
2. If not you will lose it, and it will be claimable by the owner of the `IncomeVault`.
3. Recommended having an automated keeper bot for this. (minimum time elapsed between distributions is 1 day)

## Shares Issuance 📊

1. Call `IncomeVault::issueShares()`
2. All previous non-sold shares will be applied the same price as the new ones.

## Shares Buyback 📊

1. Just transfer shares back to an address you control.

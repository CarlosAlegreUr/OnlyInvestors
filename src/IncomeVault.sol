// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IIncomeVault} from "./interfaces/IIncomeVault.sol";
import {IIncomeSourceSender} from "./interfaces/IIncomeSourceSender.sol";

contract IncomeInvestmentAgreement is IIncomeVault, ERC4626 {
    IERC20 public immutable s_purchaseToken;
    IERC20 public immutable s_incomeToken;
    uint256 public immutable s_priceOfTokenPerShare;

    /// @dev The address that will receive the income which will be distributed as dividends.
    IIncomeSourceSender public immutable s_incomeSource;
    /// @dev The address that will receive the profits from sells to the investors.
    address public s_profitReceiver;

    /**
     * @dev If the `purchaseToken` is address(0) this means that the `purchaseToken` is the native coin. (msg.value)
     * @dev If the `incomeToken` is address(0) this means that the `incomeToken` is the native coin. (msg.value)
     */
    constructor(
        IERC20 purchaseTokenAddress,
        IERC20 incomeTokenAddress,
        uint256 priceOfTokenPerShare,
        IIncomeSourceSender incomeSource
    ) ERC4626(incomeTokenAddress) ERC20("Income-Investment-Agreement-Shares", "IIAS") {
        s_purchaseToken = purchaseTokenAddress;
        s_incomeToken = incomeTokenAddress;
        s_priceOfTokenPerShare = priceOfTokenPerShare;
        s_incomeSource = incomeSource;
    }

    function invest(uint256 expectedShares) external payable override {
        uint256 tokenAmountToPay = expectedShares * s_priceOfTokenPerShare;
        uint256 sharesBeforeMint = balanceOf(msg.sender);

        // payment to buy the shares
        if (address(s_purchaseToken) == address(0)) {
            require(msg.value == tokenAmountToPay, "IncomeInvestmentAgreement: payment is not enough");
        } else {
            SafeERC20.safeTransferFrom(s_purchaseToken, msg.sender, s_profitReceiver, tokenAmountToPay);
        }

        // mint exactly expectedShares to msg.sender
        _mint(msg.sender, expectedShares);

        // safety check. Now double-spending `msg.value` is not possible trhough multicall
        uint256 sharesAfterMint = balanceOf(msg.sender);
        require(
            sharesAfterMint == sharesBeforeMint + expectedShares,
            "IncomeInvestmentAgreement: unexpected amount of shares minted"
        );
    }

    function collectAccruedDividend(address dividendReceiver) external {
        // transfers your total dividendns to dividendReceiver
    }

    function incomeToken() external view override returns (address) {
        return address(s_incomeToken);
    }
}

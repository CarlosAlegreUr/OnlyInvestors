// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IIncomeVault} from "./interfaces/IIncomeVault.sol";
import {IIncomeSourceSender} from "./interfaces/IIncomeSourceSender.sol";

contract IncomeInvestmentAgreement is IIncomeVault, ERC20, Ownable2Step {
    ////////////////////////////////////
    /////// SHARES RELATED STATE ///////
    ////////////////////////////////////

    IERC20 public immutable s_purchaseToken;
    IERC20 public immutable s_incomeToken;
    uint256 public s_priceOfTokenPerShare;
    uint256 public s_sharesIssued;

    /// @dev The address that will receive the income which will be distributed as dividends.
    IIncomeSourceSender public immutable s_incomeSource;
    /// @dev The address that will receive the profits from sells to the investors.
    address public s_profitReceiver;

    uint256 public remainingLastDividendAmount;
    uint256 public unclaimedDividends;
    uint256 public currentDividendPerShare;
    uint256 public previousDividendPerShare;

    ////////////////////////////////////
    ////// SECURITY RELATED STATE //////
    ////////////////////////////////////

    // @dev Delay to prevent massive minting of shares (MEV) attacks.
    // @dev When new shares are minted, they become claimable by `msg.sender` after this delay
    // @dev Minimum is 1 day.
    uint256 public immutable s_investmentStartDelay;
    // @dev Delay to prevent abuse of double spending `msg.value` when an investment ends and
    // you want to start a new one.
    uint256 public immutable s_reinvestDelay;
    uint256 public immutable s_distributionsDelay;
    uint256 public s_nextDistributionAvaibaleAt;
    uint256 public totalPendingShares;
    mapping(address => uint256) public s_investmentStart;
    mapping(address => uint256) public s_reInvestAvailableAfter;
    mapping(address => uint256) public s_amountOfSharesToReceiveAtStart;

    /**
     * @dev If the `purchaseToken` is address(0) this means that the `purchaseToken` is the native coin. (msg.value)
     * @dev If the `incomeToken` is address(0) this means that the `incomeToken` is the native coin. (msg.value)
     */
    constructor(
        address initialIncomeReceiver,
        IERC20 purchaseTokenAddress,
        IERC20 incomeTokenAddress,
        uint256 initialPriceOfTokenPerShare,
        uint256 initialSharesIssuance,
        uint256 investmentStartDelay,
        uint256 reinvestDelay,
        uint256 distributionDelay,
        IIncomeSourceSender incomeSource
    ) ERC20("Income-Investment-Agreement-Shares", "IIAS") Ownable(initialIncomeReceiver) {
        s_purchaseToken = purchaseTokenAddress;
        s_incomeToken = incomeTokenAddress;
        s_priceOfTokenPerShare = initialPriceOfTokenPerShare;
        s_sharesIssued = initialSharesIssuance;
        s_incomeSource = incomeSource;
        s_investmentStartDelay = investmentStartDelay < 1 days ? 1 days : investmentStartDelay;
        s_reinvestDelay = reinvestDelay < 1 days ? 1 days : reinvestDelay;
        s_distributionsDelay = distributionDelay < 1 days ? 1 days : distributionDelay;
        s_nextDistributionAvaibaleAt = block.timestamp + distributionDelay;
    }

    modifier onlyIncomeSourceSender() {
        require(msg.sender == address(s_incomeSource), "IncomeInvestmentAgreement: caller is not the income source");
        _;
    }

    /**
     * @dev This function pulls funds from caller to buy shares.
     *
     * For security reasons (MEV) once you buy shares you must wait until `finalizeInvestment(yourAddress)`
     * is called in oder to buy more plus a `reinvestDelay` has elapsed since that call.
     *
     * @param expectedShares The amount of shares the investor will be able to receive calling `finalizeInvestment()`
     * once the `s_investmentStartDelay` has elapsed.
     */
    function invest(uint256 expectedShares) external payable override {
        require(
            s_investmentStart[msg.sender] == 0, "IncomeInvestmentAgreement: already invested, claim your shares first"
        );
        require(
            block.timestamp >= s_reInvestAvailableAfter[msg.sender],
            "IncomeInvestmentAgreement: reinvest delay not elapsed"
        );

        uint256 tokenAmountToPay = expectedShares * s_priceOfTokenPerShare;

        // payment to buy the shares
        if (address(s_purchaseToken) == address(0)) {
            require(msg.value == tokenAmountToPay, "IncomeInvestmentAgreement: payment is not enough");
        } else {
            SafeERC20.safeTransferFrom(s_purchaseToken, msg.sender, s_profitReceiver, tokenAmountToPay);
        }

        s_investmentStart[msg.sender] = block.timestamp + s_investmentStartDelay;
        s_reInvestAvailableAfter[msg.sender] = block.timestamp + s_reinvestDelay;
        s_amountOfSharesToReceiveAtStart[msg.sender] = expectedShares;

        require(
            totalSupply() + expectedShares + totalPendingShares <= s_sharesIssued,
            "IncomeInvestmentAgreement: unexpected total supply"
        );
        totalPendingShares += expectedShares;
        emit IncomeVault__IncomeInvested(address(s_purchaseToken), tokenAmountToPay, expectedShares, msg.sender);
    }

    /**
     * @dev Anyone can claim or mint anyone their already payed shares from the `invest()` function.
     * @param investor The address of the investor that wants to claim his shares.
     */
    function finalizeInvestment(address investor) external {
        require(s_investmentStart[investor] != 0, "IncomeInvestmentAgreement: no investment to finalize");
        // after the delay, the payer can finalize the investment and claim the shares
        require(
            block.timestamp >= s_investmentStart[investor], "IncomeInvestmentAgreement: investment delay not elapsed"
        );

        // todo, after X time anyone should be able to get those shares or will be left hanging if no-one finalizes

        // CEI: check the payer invested, reset all to 0, mint him shares
        uint256 expectedShares = s_amountOfSharesToReceiveAtStart[investor];
        delete s_investmentStart[investor];
        delete s_amountOfSharesToReceiveAtStart[investor];
        s_reInvestAvailableAfter[investor] = block.timestamp + s_reinvestDelay;
        totalPendingShares -= expectedShares;

        // mint exactly expectedShares to investor
        _mint(investor, expectedShares);
    }

    /**
     * @dev Only the owner can issue new shares.
     *
     * Issuing shares does not mint them, it just allows anyone to buy more through `invest()`.
     *
     * Buy back of shares would be transferring shares to the current `incomeReceiver` from the
     * linked `IncomeSourceSender(s_incomeSource)` contract.
     *
     * @param amount Amount of shares to issue.
     * @param price Price at which people will be able to buy shares from now on. Note that not bought
     * previously issued shares will also get this price.
     */
    function issueShares(uint256 amount, uint256 price) external onlyOwner {
        s_priceOfTokenPerShare = price;
        s_sharesIssued += amount;
        emit IncomeVault__SharesIssued(amount, price);
    }

    function distributeDividend(uint256 amount) external onlyIncomeSourceSender {
        require(
            block.timestamp >= s_nextDistributionAvaibaleAt, "IncomeInvestmentAgreement: distribution delay not elapsed"
        );
        require(amount > 0, "IncomeInvestmentAgreement: not enough dividends to distribute");
        unclaimedDividends += remainingLastDividendAmount;

        remainingLastDividendAmount = amount;
        previousDividendPerShare = currentDividendPerShare;
        currentDividendPerShare += amount / totalSupply();

        s_nextDistributionAvaibaleAt = block.timestamp + s_distributionsDelay;
        emit IncomeVault__DividendDistributed(address(s_incomeToken), amount, address(s_incomeSource));
    }

    function collectDividend(address dividendReceiver) external {
        uint256 dividendPerShareSinceLastCollection = currentDividendPerShare - previousDividendPerShare;
        uint256 dividendAmount = dividendPerShareSinceLastCollection * balanceOf(msg.sender);
        require(dividendAmount > 0, "IncomeInvestmentAgreement: no dividends to collect");

        // create switch case in case of dividends being other tokens... todo
        if (address(s_incomeToken) == address(0)) {
            Address.sendValue(payable(dividendReceiver), dividendAmount);
        } else {
            SafeERC20.safeTransfer(s_incomeToken, dividendReceiver, dividendAmount);
        }

        remainingLastDividendAmount -= dividendAmount;
        emit IncomeVault__DividendCollected(address(s_incomeToken), dividendAmount, dividendReceiver);
    }

    function incomeToken() external view override returns (address) {
        return address(s_incomeToken);
    }

    // TODO fuction for admin to gather not claimed dividends
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IIncomeVault} from "./interfaces/IIncomeVault.sol";
import {IIncomeSourceSender} from "./interfaces/IIncomeSourceSender.sol";

/**
 * @title IncomeSourceSender
 * @author @CarlosAlegreUr
 * @dev This contract receives income from trusted sources and distributes it between an income vault and an income receiver
 * abiding by the percentage set at constrution time.
 */
contract IncomeSourceSender is IIncomeSourceSender, Ownable2Step {
    using Address for address;

    uint256 public immutable PERCENTAGE_OF_INCOME_DISTRIBUTED;
    uint256 public constant BIPS_DIVISOR = 10_000;
    mapping(address => bool) public s_incomeSources;
    IIncomeVault public immutable s_incomeVault;
    // @dev The address that will receive all funds that don't go to the income vault.
    address public s_incomeReceiver;

    ///////////////// COSTRUCTOR AND MODIFIER /////////////////

    /**
     * @param initialOwner make sure to set this to an address you control and can interact with this contract.
     * Ideally it should be the `s_incomeReceiver` address.
     */
    constructor(uint256 percentageOfIncomeDistributed, IIncomeVault incomeVault, address initialOwner)
        Ownable(initialOwner)
    {
        require(percentageOfIncomeDistributed <= BIPS_DIVISOR, "IncomeSourceSender: invalid percentage");
        PERCENTAGE_OF_INCOME_DISTRIBUTED = percentageOfIncomeDistributed;
        s_incomeVault = incomeVault;
    }

    modifier callerIsIncomeSource() {
        require(s_incomeSources[msg.sender], "IncomeSourceSender: caller is not an income source");
        _;
    }

    ///////////////// EXTERNAL FUCTIONS /////////////////

    /**
     * @dev Distributes `PERCENTAGE_OF_INCOME_DISTRIBUTED` precentage of `_amount`
     * to `s_incomeVault` and the rest goes to `s_incomeReceiver`.
     * @param payMode Whether the income is in native token or any other token standard.
     * @param _amount Total amount of income received.
     */
    function distributeIncome(uint8 payMode, uint256 _amount) external payable override callerIsIncomeSource {
        address incomeVault = address(s_incomeVault);
        address incomeToken = s_incomeVault.incomeToken();

        // safety check. Safety check will also require a switch case in the future when more tokens are supported.
        uint256 balanceSafetyCheck =
            (incomeToken == address(0)) ? incomeVault.balance : IERC20(incomeToken).balanceOf(incomeVault);

        // @dev This might round down to 0 for low decimal tokens or dust amounts. For now just be careful (:D).
        uint256 amountToDistribute = (_amount * PERCENTAGE_OF_INCOME_DISTRIBUTED) / BIPS_DIVISOR;
        uint256 amountToReceiver = _amount - amountToDistribute;

        // distribution logic
        _switchCasePayModeAndDistributeAmounts(payMode, _amount, amountToDistribute, amountToReceiver);

        // safety check
        uint256 balannceSafetyCheckAfter =
            (incomeToken == address(0)) ? incomeVault.balance : IERC20(incomeToken).balanceOf(incomeVault);
        require(
            balannceSafetyCheckAfter == balanceSafetyCheck + amountToDistribute,
            "IncomeSourceSender: unexpected amount of income received"
        );
        emit IncomeSourceSender__IncomeDistributed(payMode, _amount, s_incomeReceiver);
    }

    /**
     * @param sourceOfIncome Trusted source of income that will be allowed to call `distributeIncome()`.
     * @param isIncomeSource True if `sourceOfIncome` is allowed to call `distributeIncome()`, false otherwise.
     */
    function setSourceOfIncome(address sourceOfIncome, bool isIncomeSource) external onlyOwner {
        bool actuallyUpdated = s_incomeSources[sourceOfIncome] != isIncomeSource;
        if (actuallyUpdated) {
            s_incomeSources[sourceOfIncome] = isIncomeSource;
            emit IncomeSourceSender__SourceOfIncomeUpdated(sourceOfIncome, isIncomeSource);
        }
    }

    function setIncomeReceiver(address receiver) external onlyOwner {
        emit IncomeSourceSender__IncomeReceiverUpdated(s_incomeReceiver, receiver);
        s_incomeReceiver = receiver;
    }

    ///////////////// INTERNAL FUCTIONS /////////////////

    function _switchCasePayModeAndDistributeAmounts(
        uint256 payMode,
        uint256 _amount,
        uint256 amountToDistribute,
        uint256 amountToReceiver
    ) private {
        // @dev For future development supporting more kinds of tokens a similar method to switch case statmenet will be used.
        // if paymode is 0 transfer native
        // else ERC20
        if (payMode == 0) {
            _distributeNative(_amount, amountToDistribute, amountToReceiver);
        } else {
            _distributeERC20(_amount, amountToDistribute, amountToReceiver);
        }
    }

    function _distributeNative(uint256 _amount, uint256 amountToDistribute, uint256 amountToReceiver) private {
        require(_amount == msg.value, "IncomeSourceSender: native value sent and amount differ");
        Address.sendValue(payable(address(s_incomeVault)), amountToDistribute);
        Address.sendValue(payable(s_incomeReceiver), amountToReceiver);
    }

    function _distributeERC20(uint256, /*_amount*/ uint256 amountToDistribute, uint256 amountToReceiver) private {
        address incomeToken = s_incomeVault.incomeToken();
        SafeERC20.safeTransferFrom(IERC20(incomeToken), msg.sender, address(s_incomeVault), amountToDistribute);
        SafeERC20.safeTransferFrom(IERC20(incomeToken), msg.sender, s_incomeReceiver, amountToReceiver);
    }
}

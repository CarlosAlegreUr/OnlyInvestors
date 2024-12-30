// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IIncomeSourceSender
 * @author @CarlosAlegreUr
 * @dev This interface must be implemented by contracts that receive an income source which will be distributed
 * between an income vault and an income receiver.
 */
interface IIncomeSourceSender {
    event IncomeSourceSender__SourceOfIncomeUpdated(address sourceOfIncome, bool isIncomeSource);
    event IncomeSourceSender__IncomeReceiverUpdated(address previousIncomeReceiver, address newIncomeReceiver);
    event IncomeSourceSender__IncomeDistributed(uint8 payMode, uint256 amount, address incomeReceiver);

    /**
     * @dev Only allowed addresses set with `setSourceOfIncome(address, true)` must be allowed to call this function.
     * @param payMode Bit mask to specify the payment mode. Native coin (msg.value), ERC20, ERC721, etc.
     * @param _amount Total amount to distribute between income vault and income receiver.
     */
    function distributeIncome(uint8 payMode, uint256 _amount) external payable;

    /**
     * @dev Grants or revokes address `sourceOfIncome` permission to call `distributeIncome()`.
     * @dev Ideally it is controlled by the incomve receiver.
     */
    function setSourceOfIncome(address sourceOfIncome, bool isIncomeSource) external;

    /**
     * @dev Sets the address that will receive the income which will not be distributed as dividends.
     * Ideally access to this function is permissioned and controlled by the same entity that controls `incomeReceiver`.
     */
    function setIncomeReceiver(address incomeReceiver) external;
}

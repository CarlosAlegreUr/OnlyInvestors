// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IIncomeVault {
    function invest(uint256 expectedShares) external payable;
    function collectAccruedDividend(address dividendReceiver) external;
    function incomeToken() external view returns (address);
}

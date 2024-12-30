// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
// todo improve events and complete interfaces, docs, inheritance from other interfaces etc
interface IIncomeVault {
    event IncomeVault__IncomeInvested(address indexed incomeToken, uint256 amount, uint256 shares, address indexed investor);
    event IncomeVault__IncomeCollected(address indexed incomeToken, uint256 amount, address indexed collector);
    event IncomeVault__DividendCollected(address indexed incomeToken, uint256 amount, address indexed collector);
    event IncomeVault__DividendDistributed(address indexed incomeToken, uint256 amount, address indexed dividendReceiver);
    event IncomeVault__SharesIssued(uint256 amount, uint256 price);

    function invest(uint256 expectedShares) external payable;
    function collectDividend(address dividendReceiver) external;
    function issueShares(uint256 amount, uint256 price) external;
    function incomeToken() external view returns (address);
    function distributeDividend(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// file-scope custom errors so you can `revert LP_UnlistedAsset();` etc.
error NotEnoughCollateral();
error HealthFactorTooLow();
error AmountTooSmall();
error TransferFailed();
error InsufficientBalance();
error InvalidAsset();
error NotAuthorized();
error DebtNotRepaid();
error LP_NotAllowed();
error LP_UnlistedAsset();
error LP_InvalidAmount();
error LP_InsufficientBalance();
error LP_NotEnoughLiquidity();

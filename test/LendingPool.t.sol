// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {Oracle} from "../src/utils/Oracle.sol";
import {AToken} from "../src/tokens/AToken.sol";
import {DebtToken} from "../src/tokens/DebtToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {InterestRateModel} from "../src/utils/InterestRateModel.sol";

contract MockERC20 is ERC20 {
    constructor(string memory n, string memory s, uint256 supply) ERC20(n, s) {
        _mint(msg.sender, supply);
    }

    function mint(address to, uint256 amt) external {
        _mint(to, amt);
    }
}

contract LendingPoolTest is Test {
    LendingPool pool;
    Oracle oracle;
    MockERC20 dai;
    MockERC20 weth;
    AToken aDai;
    DebtToken dDai;
    AToken aWeth;
    DebtToken dWeth;

    address alice;
    address bob;

    function setUp() public {
        alice = address(0xA11ce);
        bob = address(0xB0b);

        // deploy oracle + pool
        oracle = new Oracle();
        pool = new LendingPool(address(oracle));

        // deploy mocks
        dai = new MockERC20("Mock DAI", "DAI", 1e24); // 1M
        weth = new MockERC20("Mock WETH", "WETH", 1e24);

        // deploy aTokens & debt tokens (owner set to test contract)
        aDai = new AToken("aDAI", "aDAI", address(this));
        dDai = new DebtToken("dDAI", "dDAI", address(this));
        aWeth = new AToken("aWETH", "aWETH", address(this));
        dWeth = new DebtToken("dWETH", "dWETH", address(this));

        // set underlying in aTokens
        aDai.setUnderlying(address(dai));
        aWeth.setUnderlying(address(weth));

        // List reserves
        pool.listReserve(address(dai), aDai, dDai, InterestRateModel(address(0)), true, 7500, 8000, 10500);
        pool.listReserve(address(weth), aWeth, dWeth, InterestRateModel(address(0)), true, 7000, 7500, 10750);

        // set prices: DAI = $1, WETH = $3000 (prices are 1e8)
        oracle.setPrice(address(dai), int256(1 * 1e8));
        oracle.setPrice(address(weth), int256(3000 * 1e8));

        // give users tokens
        dai.mint(alice, 1000 ether);
        weth.mint(bob, 10 ether);

        // approve pool transfers (simulate user approvals)
        vm.prank(alice);
        dai.approve(address(pool), type(uint256).max);
        vm.prank(bob);
        weth.approve(address(pool), type(uint256).max);
    }

    function testDepositBorrowRepayWithdraw() public {
        // alice deposits 1000 DAI
        vm.prank(alice);
        pool.deposit(address(dai), 1000 ether);

        // ensure aToken balance
        assertEq(aDai.balanceOf(alice), 1000 ether);

        // bob deposits 10 WETH
        vm.prank(bob);
        pool.deposit(address(weth), 10 ether);
        assertEq(aWeth.balanceOf(bob), 10 ether);

        // bob borrows 1000 DAI (collateral WETH: 10 * $3000 = $30,000; with LTV 70% -> $21,000 available)
        vm.prank(bob);
        pool.borrow(address(dai), 1000 ether);
        assertEq(dDai.balanceOf(bob), 1000 ether);

        // bob repays 500 DAI
        dai.mint(bob, 500 ether);
        vm.prank(bob);
        dai.approve(address(pool), 500 ether);
        vm.prank(bob);
        pool.repay(address(dai), 500 ether);
        assertEq(dDai.balanceOf(bob), 500 ether);

        // alice withdraws 100 DAI
        vm.prank(alice);
        pool.withdraw(address(dai), 100 ether);
        assertEq(aDai.balanceOf(alice), 900 ether);
    }
}

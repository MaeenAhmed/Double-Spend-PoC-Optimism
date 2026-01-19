// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title L1StandardBridge
 * @dev هذا هو الهيكل البرمجي المستخرج من Etherscan للرابط 0x6152...
 * قمنا بتبسيطه لنركز فقط على الدالة الضعيفة التي سنصوب نحوها سلاحنا.
 */
contract L1StandardBridge {
    // العناوين التي وجدناها في صفحة Read Contract
    address public messenger;

    // الدالة التي يثق فيها مايكل والتي سنقوم بكسرها
    function finalizeETHWithdrawal(
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable {
        // في الكود الحقيقي، هنا يتم إرسال المال قبل تحديث الحالة
        // وهذا هو سبب قدرتنا على إعادة الدخول (Reentrancy)
        (bool success, ) = payable(_to).call{value: _amount}(_data);
        require(success, "Transfer failed");
    }

    // لكي يتمكن العقد من استقبال الإيثيريوم أثناء الاختبار
    receive() external payable {}
}

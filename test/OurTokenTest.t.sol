// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";
import {Test, console} from "forge-std/Test.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address joe = makeAddr("joe");
    address doe = makeAddr("doe");
    address bob = makeAddr("bob"); // New address for additional testing

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(address(msg.sender));
        ourToken.transfer(joe, STARTING_BALANCE);
    }

    function testJoeBalance() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(joe));
    }

    function testTransferAllowanceWorks() public {
        uint256 initialAllowance = 1000;

        // Joe approves Doe to spend tokens on his behalf.
        // approve function can be found in the OpenZepplin ERC20 file
        vm.prank(joe);
        ourToken.approve(doe, initialAllowance);

        // Now transfer the funds to Doe
        uint256 transferAmount = 500;

        vm.prank(doe);
        ourToken.transferFrom(joe, doe, transferAmount); // Not ourToken.transfer. See difference in ERC20 file.

        assertEq(ourToken.balanceOf(doe), transferAmount);
        assertEq(ourToken.balanceOf(joe), STARTING_BALANCE - transferAmount);
    }

    function testTransferFromWithoutAllowanceReverts() public {
        // Bob tries to transfer tokens from Joe without approval
        uint256 transferAmount = 500;

        vm.prank(bob);
        vm.expectRevert();
        ourToken.transferFrom(joe, doe, transferAmount);
    }

    function testAllowanceIsNotIncreasedOrDecreasedButOnlyUpdated() public {
        uint256 initialAllowance = 1000;
        uint256 increaseAllowance = 500;
        uint256 decreaseAllowance = 500;

        // Joe approves Doe to spend tokens on his behalf.
        vm.prank(joe);
        ourToken.approve(doe, initialAllowance);

        // Increase the allowance for Doe
        vm.prank(joe);
        ourToken.approve(doe, increaseAllowance);

        // Ensure the allowance is not increased, only updated
        assertEq(ourToken.allowance(joe, doe), increaseAllowance);

        // Decrease the allowance for Doe
        vm.prank(joe);
        ourToken.approve(doe, increaseAllowance);

        // Ensure the allowance is not decreased, only updated
        assertEq(ourToken.allowance(joe, doe), decreaseAllowance);

        // The logic with allowwwance is that
        // Despite an initial approval, if a new allowance is approved for an account
        // It doesn't add or minus the previous allowance
        // It acts as a fresh allowance
    }

    function testTransfer() public {
        // Joe transfers tokens to Doe
        uint256 transferAmount = 500;
        vm.prank(joe);
        ourToken.transfer(doe, transferAmount);

        assertEq(ourToken.balanceOf(doe), transferAmount);
        assertEq(ourToken.balanceOf(joe), STARTING_BALANCE - transferAmount);
    }

    function testTransferFrom() public {
        // Joe approves Doe to spend tokens on his behalf.
        uint256 initialAllowance = 1000;
        vm.prank(joe);
        ourToken.approve(doe, initialAllowance);

        // Doe transfers tokens from Joe's account to Bob's account
        uint256 transferAmount = 500;

        vm.prank(doe);
        ourToken.transferFrom(joe, bob, transferAmount);

        assertEq(ourToken.balanceOf(bob), transferAmount);
        assertEq(ourToken.balanceOf(joe), STARTING_BALANCE - transferAmount);
        assertEq(
            ourToken.allowance(joe, doe),
            initialAllowance - transferAmount
        );
    }

    function testTransferToZeroAddressFails() public {
        // Joe tries to transfer tokens to the zero address
        uint256 transferAmount = 500;

        vm.expectRevert();
        vm.prank(joe);
        ourToken.transfer(address(0), transferAmount);
    }

    function testTransferFromToZeroAddressFails() public {
        // Joe approves Doe to spend tokens on his behalf.
        uint256 initialAllowance = 1000;
        vm.prank(joe);
        ourToken.approve(doe, initialAllowance);

        // Doe tries to transfer tokens from Joe's account to the zero address
        uint256 transferAmount = 500;
        vm.prank(doe);
        vm.expectRevert();
        ourToken.transferFrom(joe, address(0), transferAmount);
    }

    function testTransferWithInsufficientBalanceFails() public {
        // Joe tries to transfer more tokens than he has
        uint256 transferAmount = STARTING_BALANCE + 1;
        vm.prank(joe);
        vm.expectRevert();
        ourToken.transfer(doe, transferAmount);
    }

    function testTransferFromWithInsufficientAllowanceFails() public {
        // Joe approves Doe to spend tokens on his behalf, but with insufficient allowance
        uint256 initialAllowance = 100;
        vm.prank(joe);
        ourToken.approve(doe, initialAllowance);
        vm.prank(doe);
        // Doe tries to transfer tokens from Joe's account, exceeding the allowance
        uint256 transferAmount = initialAllowance + 1;

        vm.expectRevert();
        ourToken.transferFrom(joe, bob, transferAmount);
    }
}

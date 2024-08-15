// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../contracts/FunSwap.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title TestToken - A simple ERC20 token for testing purposes
/// @notice This contract is used to test the token swap functionality in FunSwap
contract TestToken is ERC20 {
    /// @notice Deploys the token with an initial supply to the deployer
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param initialSupply The initial supply of tokens
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

/// @title FunSwapTest - Test suite for FunSwap contract
/// @notice This contract contains test cases to verify the functionality of the FunSwap contract
contract FunSwapTest {
    FunSwap public funSwap;
    TestToken public token1;
    TestToken public token2;

    address public partyA;
    address public partyB;

    uint256 public constant INITIAL_SUPPLY = 1000000 ether;
    uint256 public constant SWAP_AMOUNT1 = 100 ether;
    uint256 public constant SWAP_AMOUNT2 = 50 ether;
    uint256 public deadline;

    /// @notice Deploys tokens and sets up the FunSwap contract for testing
    /// @dev Initializes partyA as the deployer and partyB as a mock address
    constructor() {
        partyA = msg.sender; // The test contract deployer will be partyA
        partyB = address(0x1); // Mock address for partyB

        // Deploy test tokens
        token1 = new TestToken("TokenA", "TKA", INITIAL_SUPPLY);
        token2 = new TestToken("TokenB", "TKB", INITIAL_SUPPLY);

        // Set the swap deadline
        deadline = block.timestamp + 1 days;

        // Deploy the FunSwap contract
        funSwap = new FunSwap(
            address(token1),
            address(token2),
            partyA,
            partyB,
            SWAP_AMOUNT1,
            SWAP_AMOUNT2,
            deadline
        );

        // Transfer initial token amounts to partyB
        token1.transfer(partyB, 500000 ether);
        token2.transfer(partyB, 500000 ether);
    }

    /// @notice Tests whether PartyA can approve and initiate the swap for Token1
    /// @dev PartyA approves the token transfer and calls the FunSwap contract's approveSwap function
    function testApproveSwapByPartyA() public {
        // PartyA approves the swap amount for Token1
        token1.approve(address(funSwap), SWAP_AMOUNT1);

        // PartyA approves the swap
        funSwap.approveSwap();

        // Check if the contract received Token1 from PartyA
        require(token1.balanceOf(address(funSwap)) == SWAP_AMOUNT1, "Token1 not transferred to contract");
    }

    /// @notice Tests whether PartyB can approve and initiate the swap for Token2
    /// @dev This test assumes that PartyB is manually set in Remix, and approves the token transfer
    function testApproveSwapByPartyB() public {
        // PartyB approves the swap amount for Token2
        token2.approve(address(funSwap), SWAP_AMOUNT2);

        // PartyB approves the swap
        funSwap.approveSwap();

        // Check if the contract received Token2 from PartyB
        require(token2.balanceOf(address(funSwap)) == SWAP_AMOUNT2, "Token2 not transferred to contract");
    }

    /// @notice Tests whether the swap is marked as completed after both approvals
    /// @dev Checks the isCompleted state of the FunSwap contract
    function testSwapCompletion() public {
        // Check that the swap is completed

        require(funSwap.isCompleted() == true, "Swap should be completed");
    }

    /// @notice Tests that the swap cannot expire before the deadline
    /// @dev Attempts to expire the swap before the deadline and expects failure
    function testCannotExpireBeforeDeadline() public {
        bool success = false;

        // Try to expire the swap before the deadline
        try funSwap.expireSwap() {
            success = true;
        } catch {
            success = false;
        }

        require(success == false, "Swap should not expire before deadline");
    }

    /// @notice Tests whether the swap can expire after the deadline
    /// @dev Ensure that the test runs after the swap's deadline has passed, and expire the swap
    function testExpireSwapAfterDeadline() public {
        // Manually ensure the block timestamp is after the deadline
        require(block.timestamp > deadline, "Deadline has not passed yet");

        // Expire the swap after the deadline
        funSwap.expireSwap();

        // Check if the swap is marked as expired
        require(funSwap.isCompleted() == true, "Swap should be marked as expired");
    }

    /// @notice Tests whether PartyA can recover tokens after the swap expires
    /// @dev Calls the recoverTokens function and checks if the tokens were transferred back to PartyA
    function testRecoverTokensAfterExpiration() public {
        // Simulate the swap being expired and recovering tokens
        funSwap.recoverTokens(address(token1));
        
        // Verify that tokens have been recovered to partyA
        require(token1.balanceOf(partyA) == SWAP_AMOUNT1, "Tokens should be recovered to PartyA");
    }

    /// @notice Tests whether PartyA can extend the swap deadline
    /// @dev PartyA extends the deadline and checks if the new deadline is set correctly
    function testExtendDeadline() public {
        uint256 newDeadline = block.timestamp + 2 days;

        // Extend the swap deadline by PartyA
        funSwap.extendDeadline(newDeadline);

        // Verify that the deadline is updated
        require(funSwap.deadline() == newDeadline, "Deadline extension failed");
    }
}

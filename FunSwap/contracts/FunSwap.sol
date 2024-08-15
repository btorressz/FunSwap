// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title FunSwap - A simple token swapping contract between two parties
/// @notice This contract allows two parties to swap tokens between each other with optional expiration handling
/// @dev This contract uses the ReentrancyGuard to prevent reentrancy attacks
contract FunSwap is ReentrancyGuard {
    /// @notice The address of the first token in the swap (Token A)
    address public token1;

    /// @notice The address of the second token in the swap (Token B)
    address public token2;

    /// @notice The address of party A (who owns Token A)
    address public partyA;

    /// @notice The address of party B (who owns Token B)
    address public partyB;

    /// @notice The amount of Token A to be swapped
    uint256 public amountToken1;

    /// @notice The amount of Token B to be swapped
    uint256 public amountToken2;

    /// @notice The deadline by which the swap must be completed
    uint256 public deadline;

    /// @notice A grace period after the deadline before the swap is considered expired
    uint256 public gracePeriod = 1 hours;

    /// @dev Internal flags to track the swap state (0 = not completed, 1 = completed)
    uint8 private flags;

    /// @notice Indicates whether the swap has been completed or not
    bool public isCompleted;

    /// @notice The different states the swap can be in
    enum SwapStatus { Initiated, Completed, Expired }
    SwapStatus public status;

    /// @notice Emitted when the swap is initiated
    /// @param partyA The address of party A (Token A owner)
    /// @param partyB The address of party B (Token B owner)
    /// @param amountToken1 The amount of Token A being swapped
    /// @param amountToken2 The amount of Token B being swapped
    /// @param deadline The deadline by which the swap must be completed
    event SwapInitiated(address indexed partyA, address indexed partyB, uint256 amountToken1, uint256 amountToken2, uint256 deadline);

    /// @notice Emitted when the swap is completed
    /// @param partyA The address of party A
    /// @param partyB The address of party B
    event SwapCompleted(address indexed partyA, address indexed partyB);

    /// @notice Emitted when the swap expires
    /// @param partyA The address of party A
    /// @param partyB The address of party B
    event SwapExpired(address indexed partyA, address indexed partyB);

    /// @notice Emitted when tokens are recovered after expiration
    /// @param token The address of the token recovered
    /// @param recipient The address of the recipient who recovered the tokens
    /// @param amount The amount of tokens recovered
    event TokenRecovered(address indexed token, address indexed recipient, uint256 amount);

    /// @notice Emitted when the swap deadline is extended
    /// @param newDeadline The new deadline for the swap
    event DeadlineExtended(uint256 newDeadline);

    /// @dev Ensures that only party A can call a function
    modifier onlyPartyA() {
        require(msg.sender == partyA, "Not authorized");
        _;
    }

    /// @dev Ensures that only party B can call a function
    modifier onlyPartyB() {
        require(msg.sender == partyB, "Not authorized");
        _;
    }

    /// @dev Ensures that a function can only be called before the swap deadline
    modifier onlyBeforeDeadline() {
        require(block.timestamp < deadline, "Swap deadline passed");
        _;
    }

    /// @dev Ensures that a function can only be called before the grace period ends
    modifier onlyBeforeGracePeriod() {
        require(block.timestamp < deadline + gracePeriod, "Swap grace period passed");
        _;
    }

    /// @dev Ensures that a function can only be called after the swap deadline
    modifier onlyAfterDeadline() {
        require(block.timestamp >= deadline, "Swap deadline not reached");
        _;
    }

    /// @dev Ensures that a function can only be called if the swap has not been completed
    modifier onlyIfNotCompleted() {
        require(flags == 0, "Swap already completed");
        _;
    }

    /// @dev Ensures that a function can only be called if the swap has been completed
    modifier onlyIfCompleted() {
        require(flags == 1, "Swap not completed");
        _;
    }

    /// @notice Receives ETH (if needed)
    receive() external payable {
        // Optionally handle ETH transfers if needed
    }

    /// @notice Reverts any fallback calls with no data
    fallback() external {
        revert("No ETH transfers allowed");
    }

    /// @notice Constructor to initialize the contract with tokens, parties, and amounts
    /// @param _token1 The address of the first token (Token A)
    /// @param _token2 The address of the second token (Token B)
    /// @param _partyA The address of party A (owner of Token A)
    /// @param _partyB The address of party B (owner of Token B)
    /// @param _amountToken1 The amount of Token A to be swapped
    /// @param _amountToken2 The amount of Token B to be swapped
    /// @param _deadline The deadline by which the swap must be completed
    constructor(
        address _token1,
        address _token2,
        address _partyA,
        address _partyB,
        uint256 _amountToken1,
        uint256 _amountToken2,
        uint256 _deadline
    ) {
        token1 = _token1;
        token2 = _token2;
        partyA = _partyA;
        partyB = _partyB;
        amountToken1 = _amountToken1;
        amountToken2 = _amountToken2;
        deadline = _deadline;
        status = SwapStatus.Initiated;
        isCompleted = false;

        emit SwapInitiated(partyA, partyB, amountToken1, amountToken2, deadline);
    }

    /// @notice Approves the swap of tokens between the parties
    /// @dev Ensures the swap is only completed if both tokens have been transferred to the contract
    function approveSwap() external onlyBeforeDeadline onlyIfNotCompleted nonReentrant {
        if (msg.sender == partyA) {
            require(IERC20(token1).transferFrom(partyA, address(this), amountToken1), "Token1 transfer failed");
        } else if (msg.sender == partyB) {
            require(IERC20(token2).transferFrom(partyB, address(this), amountToken2), "Token2 transfer failed");
        } else {
            revert("Not authorized");
        }

        if (IERC20(token1).balanceOf(address(this)) >= amountToken1 && IERC20(token2).balanceOf(address(this)) >= amountToken2) {
            status = SwapStatus.Completed;
            flags = 1;
            isCompleted = true;
            emit SwapCompleted(partyA, partyB);
        }
    }

    /// @notice Expires the swap if the deadline has passed and neither party has completed the swap
    function expireSwap() external onlyAfterDeadline onlyBeforeGracePeriod onlyIfNotCompleted nonReentrant {
        status = SwapStatus.Expired;
        flags = 1;
        isCompleted = true;
        emit SwapExpired(partyA, partyB);
    }

    /// @notice Recovers tokens after the swap expires
    /// @param token The address of the token to be recovered
    function recoverTokens(address token) external onlyAfterDeadline onlyIfNotCompleted nonReentrant {
        require(status == SwapStatus.Expired, "Swap not expired");
        require(token == token1 || token == token2, "Invalid token for recovery");

        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No tokens to recover");

        if (token == token1) {
            require(IERC20(token1).transfer(partyA, balance), "Token1 transfer failed");
        } else if (token == token2) {
            require(IERC20(token2).transfer(partyB, balance), "Token2 transfer failed");
        }

        emit TokenRecovered(token, msg.sender, balance);
    }

    /// @notice Extends the deadline for the swap
    /// @param newDeadline The new deadline for the swap
    function extendDeadline(uint256 newDeadline) external onlyPartyA onlyBeforeDeadline {
        require(newDeadline > deadline, "New deadline must be later than current deadline");
        deadline = newDeadline;
        emit DeadlineExtended(newDeadline);
    }

    /// @notice Internal function to safely approve token transfers
    /// @param token The ERC-20 token to approve
    /// @param spender The address allowed to spend the tokens
    /// @param amount The amount of tokens to approve
    function _safeApprove(IERC20 token, address spender, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), spender);
        if (currentAllowance < amount) {
            require(token.approve(spender, amount), "Approval failed");
        }
    }
}

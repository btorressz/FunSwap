# FunSwap - A Simple Token Swap Contract

**FunSwap** is a Solidity-based smart contract that allows two parties to exchange two different ERC20 tokens between each other in a decentralized and secure way. The contract supports expiration handling to ensure the swap is completed within a specified timeframe, or else tokens can be recovered after the expiration. 

This project was developed for a private client and serves as an example of the custom decentralized applications I built for clients. This project was developed in Remix IDE

## Features

- **Token Swapping**: Facilitates a secure swap between two parties using ERC20 tokens.
- **Deadline and Expiration**: Allows a deadline for the swap to ensure timely completion. Tokens can be recovered after expiration.
- **Extendable Deadline**: The swap deadline can be extended by Party A before it expires.
- **Grace Period**: Provides a grace period after the initial deadline to allow swaps even if slightly delayed.

## Smart Contract Details

### FunSwap Contract

- **Token1 (Party A Token)**: The token that Party A will swap.
- **Token2 (Party B Token)**: The token that Party B will swap.
- **Party A**: The address that owns Token1.
- **Party B**: The address that owns Token2.
- **AmountToken1**: The amount of Token1 being swapped.
- **AmountToken2**: The amount of Token2 being swapped.
- **Deadline**: The time limit within which the swap must be completed.
- **Grace Period**: An additional time window after the deadline to allow swaps to proceed.

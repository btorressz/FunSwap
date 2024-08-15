# FunSwap - A Simple Token Swap Contract

**FunSwap** is a Solidity-based smart contract that allows two parties to exchange two different ERC20 tokens between each other in a decentralized and secure way. The contract supports expiration handling to ensure the swap is completed within a specified timeframe, or else tokens can be recovered after the expiration. 

This project was developed for a private client and serves as an example of the custom decentralized applications I built for clients.

## Features

- **Token Swapping**: Facilitates a secure swap between two parties using ERC20 tokens.
- **Deadline and Expiration**: Allows a deadline for the swap to ensure timely completion. Tokens can be recovered after expiration.
- **Extendable Deadline**: The swap deadline can be extended by Party A before it expires.
- **Grace Period**: Provides a grace period after the initial deadline to allow swaps even if slightly delayed.

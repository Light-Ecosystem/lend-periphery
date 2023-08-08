
# HopeLend Periphery

This repository contains UI helpers and others external smart contracts utilities related with the HopeLend Protocol.

## What is HopeLend?

HopeLend is a decentralized non-custodial liquidity markets protocol where users can participate as suppliers or borrowers. Suppliers provide liquidity to the market to earn a passive income, while borrowers are able to borrow in an overcollateralized (perpetually) or undercollateralized (one-block liquidity) fashion.

# Audits and Security

You can find all audit reports under the audits folder

V1.0 - July 2023

- [PeckShield](./audits/30-07-2023_PeckShield_HopeLendV1.pdf)
- [Beosin](./audits/19-07-2023_Beosin_HopeLendV1_Periphery.pdf)
- [MetaTrust](./audits/29-07-2023_MetaTrust_HopeLendV1_Periphery.pdf)

There is also an active [bug bounty](https://static.hope.money/bug-bounty.html) for issues which can lead to substantial loss of money, critical bugs such as a broken live-ness condition, or irreversible loss of funds.

## Connect with the community

You can join the [Discord](https://discord.gg/hopemoneyofficial) to ask questions about the protocol or talk about HopeLend with other peers.

## Getting started

Download the dependencies

```
npm i
```

Compile the contracts

```
npm run compile
```

## Running tests

```
npm test
```

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";

contract MerkleAirDropTest is Test {
    MerkleAirdrop private merkleAirdrop;
    BagelToken private bagelToken;

    function setUp() public {}
}

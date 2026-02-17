//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {ZKSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "script/DeployMerkleAirdrop.s.sol";

contract MerkleAirDropTest is ZkSyncChainChecker, Test {
    MerkleAirdrop public merkleAirdrop;
    BagelToken public bagelToken;
    bytes32 public constant ROOT =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address user;
    uint256 public constant AMOUNT_TO_CLAIM = 25 * 1e18;
    bytes32 proofOne =
        0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo =
        0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, proofTwo];
    uint256 userPrivKey;
    address gasPayer;
    uint256 public constant AMOUNT_TO_SEND = 100 * 1e18;

    function setUp() public {
        if (!isZkSyncChain()) {
            (merkleAirdrop, bagelToken) = new DeployMerkleAirdrop()
                .deployMerkleAirdrop();
            return;
        } else {
            bagelToken = new BagelToken();
            merkleAirdrop = new MerkleAirdrop(ROOT, bagelToken);
            bagelToken.mint(bagelToken.owner(), AMOUNT_TO_SEND);
            bagelToken.transfer(address(merkleAirdrop), AMOUNT_TO_SEND);
            (user, userPrivKey) = makeAddrAndKey("user");
        }
        gasPayer = makeAddr("gasPayer");
    }

    function testUserCanClaim() public {
        uint256 startingBalance = bagelToken.balanceOf(user);

        bytes32 digest = merkleAirdrop.getMessage(user, AMOUNT_TO_CLAIM);
        console.log("User's starting balance: %s", startingBalance);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        uint256 endingBalance = bagelToken.balanceOf(user);
        console.log("User's ending balance: %s", endingBalance);
        assertEq(
            endingBalance - startingBalance,
            25 * 1e18,
            "User should have received the airdrop"
        );
    }
}

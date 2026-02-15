// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;
    // some lists of addresses
    // Allow someone in the list to claim ERC-20 tokens
    // Use a Merkle tree to verify that the address is in the list
    // Use OpenZeppelin's MerkleProof library to verify the proof
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    event Claim(address indexed account, uint256 amount);
    address[] claimers;
    bytes32 public constant MESSAGE_TYPEHASH =
        keccak256("AirdropClaim(address account,uint256 amount)");
    bytes32 private immutable I_MERKLE_ROOT;
    IERC20 private immutable I_AIRDROP_TOKEN;
    mapping(address claimer => bool claimed) private sHasClaimed;
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    constructor(
        bytes32 merkleRoot,
        IERC20 airdropToken
    ) EIP712("MerkleAirdrop", "1") {
        I_MERKLE_ROOT = merkleRoot;
        I_AIRDROP_TOKEN = airdropToken;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (sHasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        if (!_isValidSignature(account, getMessage(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encodePacked(account, amount)))
        );
        if (!MerkleProof.verify(merkleProof, I_MERKLE_ROOT, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        sHasClaimed[account] = true;

        emit Claim(account, amount);
        I_AIRDROP_TOKEN.safeTransfer(account, amount);
    }

    function getMessage(
        address account,
        uint256 amount
    ) public pure returns (bytes32) {
        return
            _hashTypeDataV4(
                keccak256(
                    abi.encodePacked(
                        MESSAGE_TYPEHASH,
                        AirdropClaim({account: account, amount: amount})
                    )
                )
            );
    }

    function _isValidSignature(
        address account,
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        (address actualSigner, , ) = ECDSA.tryRecover(messageHash, v, r, s);
        return actualSigner == account;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return I_MERKLE_ROOT;
    }

    function getClaimed(address account) external view returns (bool) {
        return sHasClaimed[account];
    }

    function getAirdropToken() external view returns (IERC20) {
        return I_AIRDROP_TOKEN;
    }
}

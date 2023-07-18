// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./MerkleTree.sol";
import "../circuits/circuit-swap/contract/plonk_vk.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/security/ReentrancyGuard.sol";

interface IVerifier {
    function verify(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external view returns (bool);
}

abstract contract ZKSwap is MerkleTreeWithHistory, ReentrancyGuard {
    enum NodeStatus {
        Available,
        Traded,
        Withdrew
    }

    // verifiers
    IVerifier public immutable depositVerifier;
    IVerifier public immutable swapVerifier;
    IVerifier public immutable finalizeVerifier;
    IVerifier public immutable withdrawVerifier;

    mapping(bytes32 => NodeStatus) public statusPool;
    // for checking collisions
    mapping(bytes32 => bool) public commitments;

    event Deposit(
        bytes32 indexed commitment,
        uint32 leafIndex,
        uint256 timestamp
    );

    event Withdrawal(
        address to,
        bytes32 nullifierHash,
        address indexed relayer,
        uint256 fee
    );

    /**
    @dev The constructor
    @param _hasher the address of MiMC hash contract
    @param _merkleTreeHeight the height of deposits' Merkle Tree
  */
    constructor(
        IVerifier _depositVerifier,
        IVerifier _swapVerifier,
        IVerifier _finalizeVerifier,
        IVerifier _withdrawVerifier,
        IHasher _hasher,
        uint32 _merkleTreeHeight
    ) MerkleTreeWithHistory(_merkleTreeHeight, _hasher) {
        depositVerifier = _depositVerifier; // Assigning the value of `_deposit_verifier` to a variable `depositVerifier`
        swapVerifier = _swapVerifier; // Assigning the value of `_swap_verifier` to a variable `swapVerifier`
        finalizeVerifier = _finalizeVerifier; // Assigning the value of `_finalize_verifier` to a variable `finalizeVerifier`
        withdrawVerifier = _withdrawVerifier;
    }

    /**
    @dev Deposit funds into the contract. The caller must send (for ETH) or approve (for ERC20) value equal to or `denomination` of this instance.
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
  */
    function deposit(bytes32 _commitment) external payable nonReentrant {
        require(!commitments[_commitment], "The commitment has been submitted");

        uint32 insertedIndex = _insert(_commitment);
        commitments[_commitment] = true;
        _processDeposit();

        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    /** @dev this function is defined in a child contract */
    function _processDeposit() internal virtual;

    /**
    @dev Withdraw a deposit from the contract. `proof` is a zkSNARK proof data, and input is an array of circuit public inputs
    `input` array consists of:
      - merkle root of all deposits in the contract
      - hash of unique deposit nullifier to prevent double spends
      - the recipient of funds
      - optional fee that goes to the transaction sender (usually a relay)
  */
    function withdraw(
        bytes calldata _proof,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) external payable nonReentrant {
        require(
            statusPool[_nullifierHash] == NodeStatus.Available,
            "The note has been already spent"
        );
        require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
        require(
            withdrawVerifier.verify(
                _proof,
                [
                    uint256(_root),
                    uint256(_nullifierHash),
                    uint256(_recipient),
                    uint256(_relayer),
                    _fee,
                    _refund
                ]
            ),
            "Invalid withdraw proof"
        );

        statusPool[_nullifierHash] = NodeStatus.Withdrew;
        _processWithdraw(_recipient, _relayer, _fee, _refund);
        emit Withdrawal(_recipient, _nullifierHash, _relayer, _fee);
    }

    /** @dev this function is defined in a child contract */
    function _processWithdraw(
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) internal virtual;

    // /** @dev whether a note is already spent */
    // function isSpent(bytes32 _nullifierHash) public view returns (bool) {
    //     return nullifierHashes[_nullifierHash];
    // }

    // /** @dev whether an array of notes is already spent */
    // function isSpentArray(
    //     bytes32[] calldata _nullifierHashes
    // ) external view returns (bool[] memory spent) {
    //     spent = new bool[](_nullifierHashes.length);
    //     for (uint256 i = 0; i < _nullifierHashes.length; i++) {
    //         if (isSpent(_nullifierHashes[i])) {
    //             spent[i] = true;
    //         }
    //     }
    // }
}

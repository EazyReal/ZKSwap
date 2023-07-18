// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract MerkleTree {
    uint256 public constant TREE_DEPTH = 8; // Depth of the Merkle tree
    bytes32[] public leaves; // Array to store the leaves

    constructor() {
        // Initialize the Merkle tree with empty leaves
        for (uint256 i = 0; i < (2 ** TREE_DEPTH); i++) {
            leaves.push(0);
        }
    }

    function insertLeaf(bytes32 leaf) public {
        require(leaves[0] == 0, "Tree is full. Cannot insert more leaves.");

        // Insert the new leaf at the next available position
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < TREE_DEPTH; i++) {
            // Compute the position of the child node
            uint256 childIndex = (currentIndex * 2) + 1;

            // Calculate the hash of the new parent node
            leaves[childIndex] = petersenHash(leaves[currentIndex], leaf);

            // Move to the next level
            currentIndex = (currentIndex * 2) + 2;
        }
    }

    function petersenHash(
        bytes32 a,
        bytes32 b
    ) internal pure returns (bytes32) {
        // Implement your Petersen hash function here
        // This is a placeholder implementation
        return keccak256(abi.encodePacked(a, b));
    }
}

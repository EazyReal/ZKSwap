use dep::std;

struct NodeData {
    nullifier: Field,
    secret: Field,
    address: Field,
    balance: Field
}

fn assertDataValid(nodeData: NodeData, index: Field, hash_path: [Field], public_root: pub Field) {
    let node = std::hash::hash_to_field([nodeData.nullifier, nodeData.secret, nodeData.balance]);
    let calculated_root = std::merkle::compute_merkle_root(node, index, hash_path);
    assert(calculated_root == public_root);
}

fn withdraw(nodeData: NodeData, index: Field, hash_path: [Field], public_root: pub Field) {
    assertDataValid(nodeData, index, hash_path, public_root);
}


#[test]
fn test_main() {
    main();

    // Uncomment to make test fail
    // main(1, 1);
}

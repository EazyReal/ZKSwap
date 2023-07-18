use dep::std;

struct NodeData {
    nullifier: Field,
    secret: Field,
    address: Field,
    balance: Field
}

fn assertDataValid(nodeData: NodeData, index: Field, hash_path: [Field], public_root: Field) {
    let node = std::hash::hash_to_field([nodeData.nullifier, nodeData.secret, nodeData.balance]);
    let calculated_root = std::merkle::compute_merkle_root(node, index, hash_path);
    assert(calculated_root == public_root);
}


// withdraw
fn main(nodeData: NodeData, index: Field, hash_path: [Field], public_root: pub Field, balance: Field) {
    assertDataValid(nodeData, index, hash_path, public_root);
}

#[test]
fn test_main() {
}

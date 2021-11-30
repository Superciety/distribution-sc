use elrond_wasm::*;
use elrond_wasm_debug::*;

fn world() -> BlockchainMock {
    let mut blockchain = BlockchainMock::new();
    blockchain.set_current_dir_from_workspace("");

    blockchain.register_contract(
        "file:output/distribution.wasm",
        Box::new(|context| Box::new(distribution::contract_obj(context))),
    );
    blockchain
}

#[test]
fn init() {
    elrond_wasm_debug::mandos_rs("mandos/init.scen.json", world());
}

#[test]
fn update_price() {
    elrond_wasm_debug::mandos_rs("mandos/update_price.scen.json", world());
}

#[test]
fn deposit() {
    elrond_wasm_debug::mandos_rs("mandos/deposit.scen.json", world());
}

#[test]
fn buy() {
    elrond_wasm_debug::mandos_rs("mandos/buy.scen.json", world());
}

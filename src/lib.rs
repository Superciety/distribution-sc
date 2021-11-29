#![no_std]

elrond_wasm::imports!();

#[elrond_wasm::contract]
pub trait Distribution {
    #[init]
    fn init(&self) {}
}

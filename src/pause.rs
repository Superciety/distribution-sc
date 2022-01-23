elrond_wasm::imports!();

#[elrond_wasm::module]
pub trait PauseModule {
    #[view(isPaused)]
    #[storage_get("pause_module:paused")]
    fn is_paused(&self) -> bool;

    fn not_paused(&self) -> bool {
        !self.is_paused()
    }

    #[storage_set("pause_module:paused")]
    fn set_paused(&self, paused: bool);

    #[only_owner]
    #[endpoint(pause)]
    fn pause_endpoint(&self) -> SCResult<()> {
        self.set_paused(true);

        Ok(())
    }

    #[only_owner]
    #[endpoint(unpause)]
    fn unpause_endpoint(&self) -> SCResult<()> {
        self.set_paused(false);

        Ok(())
    }
}

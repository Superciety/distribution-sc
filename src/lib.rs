#![no_std]

elrond_wasm::imports!();

mod pause;

#[elrond_wasm::contract]
pub trait Distribution: pause::PauseModule {
    #[init]
    fn init(&self, dist_token_id: TokenIdentifier, dist_token_price: BigUint) {
        self.distributable_token_id().set_if_empty(&dist_token_id);
        self.distributable_token_price().set_if_empty(&dist_token_price);
    }

    #[only_owner]
    #[endpoint(updatePrice)]
    fn update_price_endpoint(&self, token_price: BigUint) -> SCResult<()> {
        self.distributable_token_price().set(&token_price);
        Ok(())
    }

    #[only_owner]
    #[endpoint(updateBuyLimit)]
    fn update_buylimit_endpoint(&self, limit_amount: BigUint) -> SCResult<()> {
        self.buy_limit().set(&limit_amount);
        Ok(())
    }

    #[only_owner]
    #[payable("*")]
    #[endpoint]
    fn deposit_endpoint(&self, #[payment_token] token: TokenIdentifier) -> SCResult<()> {
        require!(token == self.distributable_token_id().get(), "invalid token");
        Ok(())
    }

    #[only_owner]
    #[endpoint(claim)]
    fn claim_endpoint(&self) -> SCResult<()> {
        let caller = self.blockchain().get_caller();
        let balance = self.blockchain().get_sc_balance(&TokenIdentifier::egld(), 0);

        require!(balance > 0, "no funds to claim");

        self.send().direct(&caller, &TokenIdentifier::egld(), 0, &balance, &[]);

        Ok(())
    }

    #[payable("EGLD")]
    #[endpoint]
    fn buy_endpoint(&self, #[payment_amount] paid_amount: BigUint) -> SCResult<()> {
        require!(paid_amount != 0, "zero really");
        require!(self.not_paused(), "sale is paused");

        if !self.buy_limit().is_empty() {
            require!(paid_amount <= self.buy_limit().get(), "buy limit exceeded");
        }

        let caller = self.blockchain().get_caller();
        let dist_token_id = self.distributable_token_id().get();
        let price_per_token = self.distributable_token_price().get();
        let available_token_amount = self.blockchain().get_sc_balance(&dist_token_id, 0);

        let token_amount = &paid_amount / &price_per_token;

        require!(token_amount <= available_token_amount, "not enough tokens available");

        self.send().direct(&caller, &dist_token_id, 0, &token_amount, &[]);

        Ok(())
    }

    #[storage_mapper("distributableToken")]
    fn distributable_token_id(&self) -> SingleValueMapper<TokenIdentifier>;

    #[storage_mapper("distributablePrice")]
    fn distributable_token_price(&self) -> SingleValueMapper<BigUint>;

    #[storage_mapper("buyLimit")]
    fn buy_limit(&self) -> SingleValueMapper<BigUint>;
}
